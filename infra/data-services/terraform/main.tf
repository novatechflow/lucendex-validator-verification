terraform {
  required_version = ">= 1.0"
  
  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = "~> 0.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "contabo" {
  oauth2_client_id     = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user          = var.contabo_api_user
  oauth2_pass          = var.contabo_api_password
}

# Generate SSH key pair for data services access
resource "tls_private_key" "data_services_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "data_services_private_key" {
  content         = tls_private_key.data_services_ssh.private_key_pem
  filename        = "${path.module}/data_services_ssh_key"
  file_permission = "0600"
}

# Save public key locally
resource "local_file" "data_services_public_key" {
  content         = tls_private_key.data_services_ssh.public_key_openssh
  filename        = "${path.module}/data_services_ssh_key.pub"
  file_permission = "0644"
}

# Create Contabo instance for XRPL Data Services
# Components: rippled API + rippled Full-History + PostgreSQL + Backend services
resource "contabo_instance" "data_services" {
  # Image: Ubuntu 22.04 LTS (default from Contabo)
  image_id = var.image_id
  
  # Product: VPS 50 NVMe (16 vCPU, 64GB RAM, 300GB NVMe) - €29.60/month
  product_id = var.instance_plan
  
  # Region: EU (Frankfurt, Germany) - closest to Malta
  region = var.region
  
  # Billing period: monthly
  period = var.period
  
  # Display name for easier identification
  display_name = "lucendex-data-services-${var.environment}"
  
  # Cloud-init user data with SSH key + database passwords
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname             = "data-services-${var.environment}"
    ssh_pubkey           = tls_private_key.data_services_ssh.public_key_openssh
    postgres_password    = var.postgres_password
    indexer_db_password  = var.indexer_db_password
    router_db_password   = var.router_db_password
    api_db_password      = var.api_db_password
  }))
  
  # Default user for SSH access
  default_user = var.default_user
}

# Note: Contabo handles firewall rules differently than Vultr
# Firewall rules are typically managed through the Contabo control panel
# or via separate API calls, not as Terraform resources.
# 
# Required ports for XRPL data services:
# - 22/tcp: SSH
# - 51234/tcp: rippled API RPC
# - 6005/tcp: rippled API WebSocket
# - 51235/tcp: rippled API peer
# - 51236/tcp: rippled History peer
# - 5432/tcp: PostgreSQL (internal/restricted)
# - 6006/tcp: rippled Full-History WebSocket (internal/restricted)
#
# These should be configured via cloud-init/UFW (already in cloud-init.yaml)
