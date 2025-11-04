output "validator_ip" {
  description = "Public IP address of the validator"
  value       = contabo_instance.validator.ip_config[0].v4[0].ip
}

output "validator_id" {
  description = "Contabo instance ID"
  value       = contabo_instance.validator.id
}

output "validator_name" {
  description = "Validator instance name"
  value       = contabo_instance.validator.name
}

output "validator_display_name" {
  description = "Validator display name"
  value       = contabo_instance.validator.display_name
}

output "validator_region" {
  description = "Deployed region"
  value       = contabo_instance.validator.region
}

output "validator_data_center" {
  description = "Data center location"
  value       = contabo_instance.validator.region
}

output "ssh_command" {
  description = "SSH command to access validator"
  value       = "ssh -i ${path.module}/validator_ssh_key root@${contabo_instance.validator.ip_config[0].v4[0].ip}"
}

output "ssh_key_path" {
  description = "Path to SSH private key"
  value       = "${path.module}/validator_ssh_key"
}

output "ssh_public_key" {
  description = "SSH public key"
  value       = tls_private_key.validator_ssh.public_key_openssh
  sensitive   = false
}

output "instance_status" {
  description = "Instance status"
  value       = contabo_instance.validator.status
}

output "instance_product" {
  description = "Instance product details"
  value       = contabo_instance.validator.product_id
}

output "monthly_cost" {
  description = "Estimated monthly cost (EUR)"
  value       = "€11.20/month (8 vCPU, 24GB RAM, 200GB NVMe)"
}

output "cost_savings" {
  description = "Monthly savings vs Vultr"
  value       = "Savings: ~$36/month (~75% cheaper than Vultr) with better specs!"
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    
    ✓ Validator deployed successfully on Contabo!
    
    SSH Access:
      ssh root@${contabo_instance.validator.ip_config[0].v4[0].ip}
    
    Quick Commands:
      cd infra/validator
      make ssh       - SSH into validator
      make status    - Check validator status
      make logs      - View rippled logs
      make health    - Health check
    
    Firewall Configuration:
      Firewall rules are managed via UFW (configured by cloud-init)
      - SSH: Port 22 (restricted if admin_ip was set)
      - XRPL P2P: Port 51235
    
    Important:
      - Save your validator keys (generated during deployment)
      - Add validator public key to UNL
      - Monitor with: make status
      - Cost: €11.20/month (vs $48/month on Vultr!)
    
  EOT
}
