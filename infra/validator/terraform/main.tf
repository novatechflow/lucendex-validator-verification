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
  api_key = var.vultr_api_key
  rate_limit  = 100
  retry_limit = 3
}

# SSH key for validator access
resource "vultr_ssh_key" "validator" {
  name    = "lucendex-validator-${var.environment}"
  ssh_key = file("${path.module}/validator_ssh_key.pub")
}

# Validator VM instance
resource "vultr_instance" "validator" {
  plan   = var.instance_plan
  region = var.region
  os_id  = var.os_id
  label  = "lucendex-xrpl-validator-${var.environment}"
  
  hostname = "xrpl-validator"
  
  ssh_key_ids = [vultr_ssh_key.validator.id]
  
  # Enable backups
  backups = "enabled"
  
  # Enable auto-backups
  backups_schedule {
    type = "daily"
  }
  
  # User data for initial setup
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    hostname = "xrpl-validator"
  }))
  
  # Wait for instance to be ready
  activation_email = false
}

# Firewall group for validator
resource "vultr_firewall_group" "validator" {
  description = "XRPL Validator Firewall"
}

# Allow XRPL peer-to-peer (51235)
resource "vultr_firewall_rule" "xrpl_peer" {
  firewall_group_id = vultr_firewall_group.validator.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "51235"
  notes             = "XRPL peer-to-peer"
}

# Allow SSH (restricted to your IP if provided)
resource "vultr_firewall_rule" "ssh" {
  firewall_group_id = vultr_firewall_group.validator.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = var.admin_ip != "" ? var.admin_ip : "0.0.0.0"
  subnet_size       = var.admin_ip != "" ? 32 : 0
  port              = "22"
  notes             = "SSH access"
}

# Allow ICMP (ping)
resource "vultr_firewall_rule" "icmp" {
  firewall_group_id = vultr_firewall_group.validator.id
  protocol          = "icmp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "ICMP ping"
}
