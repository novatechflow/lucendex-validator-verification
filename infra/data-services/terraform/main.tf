terraform {
  required_version = ">= 1.0"
  
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.19"
    }
  }
}

provider "vultr" {
  api_key     = var.vultr_api_key
  rate_limit  = 100
  retry_limit = 3
}

# SSH key for data services access
resource "vultr_ssh_key" "data_services" {
  name    = "lucendex-data-services-${var.environment}"
  ssh_key = file("${path.module}/data_services_ssh_key.pub")
}

# Data services VM instance
resource "vultr_instance" "data_services" {
  plan   = var.instance_plan
  region = var.region
  os_id  = var.os_id
  label  = "lucendex-data-services-${var.environment}"
  
  hostname = "data-services"
  
  ssh_key_ids = [vultr_ssh_key.data_services.id]
  
  # Enable backups
  backups = "enabled"
  
  # Enable auto-backups
  backups_schedule {
    type = "daily"
  }
  
  # User data for initial setup
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname             = "data-services"
    postgres_password    = var.postgres_password
    indexer_db_password  = var.indexer_db_password
    router_db_password   = var.router_db_password
    api_db_password      = var.api_db_password
  }))
  
  # Wait for instance to be ready
  activation_email = false
}

# Firewall group for data services
resource "vultr_firewall_group" "data_services" {
  description = "XRPL Data Services Firewall"
}

# Allow rippled API RPC (51234)
resource "vultr_firewall_rule" "rippled_api" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "51234"
  notes             = "rippled API node RPC"
}

# Allow rippled API WebSocket (6005)
resource "vultr_firewall_rule" "rippled_api_ws" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "6005"
  notes             = "rippled API node WebSocket"
}

# Allow rippled Full-History WebSocket (6006) - internal only via admin IP
resource "vultr_firewall_rule" "rippled_history_ws" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = var.admin_ip != "" ? var.admin_ip : "0.0.0.0"
  subnet_size       = var.admin_ip != "" ? 32 : 0
  port              = "6006"
  notes             = "rippled Full-History WebSocket (internal)"
}

# Allow rippled peer-to-peer (51235) for both nodes
resource "vultr_firewall_rule" "rippled_peer" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "51235"
  notes             = "rippled peer-to-peer"
}

# Allow PostgreSQL (5432) - internal only via admin IP
resource "vultr_firewall_rule" "postgresql" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = var.admin_ip != "" ? var.admin_ip : "0.0.0.0"
  subnet_size       = var.admin_ip != "" ? 32 : 0
  port              = "5432"
  notes             = "PostgreSQL (internal)"
}

# Allow SSH (restricted to admin IP if provided)
resource "vultr_firewall_rule" "ssh" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = var.admin_ip != "" ? var.admin_ip : "0.0.0.0"
  subnet_size       = var.admin_ip != "" ? 32 : 0
  port              = "22"
  notes             = "SSH access"
}

# Allow ICMP (ping)
resource "vultr_firewall_rule" "icmp" {
  firewall_group_id = vultr_firewall_group.data_services.id
  protocol          = "icmp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "ICMP ping"
}
