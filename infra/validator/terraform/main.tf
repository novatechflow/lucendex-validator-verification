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
  
  # Remove old Vultr state
  backend "local" {}
}

provider "contabo" {
  oauth2_client_id     = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user          = var.contabo_api_user
  oauth2_pass          = var.contabo_api_password
}

# Generate SSH key pair for validator access
resource "tls_private_key" "validator_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "validator_private_key" {
  content         = tls_private_key.validator_ssh.private_key_pem
  filename        = "${path.module}/validator_ssh_key"
  file_permission = "0600"
}

# Save public key locally
resource "local_file" "validator_public_key" {
  content         = tls_private_key.validator_ssh.public_key_openssh
  filename        = "${path.module}/validator_ssh_key.pub"
  file_permission = "0644"
}

# Create Contabo instance for XRPL validator
resource "contabo_instance" "validator" {
  # Image: Ubuntu 22.04 LTS (default from Contabo)
  image_id = var.image_id
  
  # Product: VPS 30 NVMe (8 vCPU, 24GB RAM, 200GB NVMe) - €11.20/month
  product_id = var.instance_plan
  
  # Region: EU (Frankfurt, Germany) - closest to Malta
  region = var.region
  
  # Billing period: monthly
  period = var.period
  
  # Display name for easier identification
  display_name = "lucendex-xrpl-validator-${var.environment}"
  
  # Cloud-init user data with SSH key injection
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname   = "xrpl-validator-${var.environment}"
    ssh_pubkey = tls_private_key.validator_ssh.public_key_openssh
  }))
  
  # Default user for SSH access
  default_user = var.default_user
}

# Note: Contabo handles firewall rules differently than Vultr
# Firewall rules are typically managed through the Contabo control panel
# or via separate API calls, not as Terraform resources.
# 
# Required ports for XRPL validator:
# - 22/tcp: SSH
# - 51235/tcp: XRPL peer-to-peer
#
# These should be configured in the Contabo control panel or via cloud-init/UFW
