output "data_services_ip" {
  description = "Public IP address of data services instance"
  value       = contabo_instance.data_services.ip_config[0].v4[0].ip
}

output "data_services_id" {
  description = "Contabo instance ID"
  value       = contabo_instance.data_services.id
}

output "data_services_name" {
  description = "Instance name"
  value       = contabo_instance.data_services.name
}

output "data_services_display_name" {
  description = "Instance display name"
  value       = contabo_instance.data_services.display_name
}

output "data_services_region" {
  description = "Deployed region"
  value       = contabo_instance.data_services.region
}

output "data_services_data_center" {
  description = "Data center location"
  value       = contabo_instance.data_services.region
}

output "ssh_command" {
  description = "SSH command to connect to data services"
  value       = "ssh -i ${path.module}/data_services_ssh_key root@${contabo_instance.data_services.ip_config[0].v4[0].ip}"
}

output "ssh_key_path" {
  description = "Path to SSH private key"
  value       = "${path.module}/data_services_ssh_key"
}

output "ssh_public_key" {
  description = "SSH public key"
  value       = tls_private_key.data_services_ssh.public_key_openssh
  sensitive   = false
}

output "rippled_api_endpoint" {
  description = "rippled API node RPC endpoint"
  value       = "http://${contabo_instance.data_services.ip_config[0].v4[0].ip}:51234"
}

output "rippled_api_ws_endpoint" {
  description = "rippled API node WebSocket endpoint"
  value       = "ws://${contabo_instance.data_services.ip_config[0].v4[0].ip}:6005"
}

output "rippled_history_ws_endpoint" {
  description = "rippled Full-History WebSocket endpoint (internal)"
  value       = "ws://${contabo_instance.data_services.ip_config[0].v4[0].ip}:6006"
}

output "postgresql_connection" {
  description = "PostgreSQL connection string (internal)"
  value       = "postgresql://localhost:5432/lucendex"
  sensitive   = true
}

output "instance_status" {
  description = "Instance status"
  value       = contabo_instance.data_services.status
}

output "instance_product" {
  description = "Instance product details"
  value       = contabo_instance.data_services.product_id
}

output "monthly_cost" {
  description = "Estimated monthly cost (EUR)"
  value       = "€29.60/month (16 vCPU, 64GB RAM, 300GB NVMe)"
}

output "cost_savings" {
  description = "Monthly savings vs Vultr"
  value       = "Savings: ~$66/month (~70% cheaper than Vultr) with better specs!"
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    
    ✓ Data Services deployed successfully on Contabo!
    
    SSH Access:
      ssh root@${contabo_instance.data_services.ip_config[0].v4[0].ip}
    
    Endpoints:
      rippled API RPC:  http://${contabo_instance.data_services.ip_config[0].v4[0].ip}:51234
      rippled API WS:   ws://${contabo_instance.data_services.ip_config[0].v4[0].ip}:6005
      rippled History:  ws://${contabo_instance.data_services.ip_config[0].v4[0].ip}:6006 (internal)
      PostgreSQL:       localhost:5432 (internal)
    
    Quick Commands:
      cd infra/data-services
      make ssh       - SSH into data services
      make status    - Check services status
      make logs      - View service logs
    
    Firewall Configuration:
      Firewall rules are managed via UFW (configured by cloud-init)
      - SSH: Port 22
      - rippled API RPC: Port 51234
      - rippled API WebSocket: Port 6005
      - rippled P2P: Ports 51235-51236
      - PostgreSQL: Port 5432 (internal only)
      - rippled History WS: Port 6006 (internal only)
    
    Important:
      - PostgreSQL databases and users are configured via cloud-init
      - rippled nodes will sync on first start (may take time)
      - Monitor with: make status
      - Cost: €29.60/month (vs $96/month on Vultr!)
      - Total savings: ~$100/month with both VMs!
    
  EOT
}
