output "validator_ip" {
  description = "Public IP address of the validator"
  value       = vultr_instance.validator.main_ip
}

output "validator_id" {
  description = "Vultr instance ID"
  value       = vultr_instance.validator.id
}

output "validator_hostname" {
  description = "Validator hostname"
  value       = vultr_instance.validator.hostname
}

output "validator_region" {
  description = "Deployed region"
  value       = vultr_instance.validator.region
}

output "ssh_command" {
  description = "SSH command to access validator"
  value       = "ssh -i ${path.module}/validator_ssh_key root@${vultr_instance.validator.main_ip}"
}

output "ssh_key_path" {
  description = "Path to SSH private key"
  value       = "${path.module}/validator_ssh_key"
}

output "firewall_group_id" {
  description = "Firewall group ID"
  value       = vultr_firewall_group.validator.id
}

output "instance_status" {
  description = "Instance status"
  value       = vultr_instance.validator.status
}

output "instance_plan" {
  description = "Instance plan details"
  value       = vultr_instance.validator.plan
}

output "monthly_cost" {
  description = "Estimated monthly cost (USD)"
  value       = "~$48/month (4 vCPU, 8GB RAM, 160GB SSD + backups)"
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    
    ✓ Validator deployed successfully!
    
    SSH Access:
      ssh -i terraform/validator_ssh_key root@${vultr_instance.validator.main_ip}
    
    Quick Commands:
      make ssh       - SSH into validator
      make status    - Check validator status
      make logs      - View rippled logs
      make health    - Health check
    
    Important:
      - Save your validator keys (generated during deployment)
      - Add validator public key to UNL
      - Monitor with: make status
    
  EOT
}
