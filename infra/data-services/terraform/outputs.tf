output "data_services_ip" {
  description = "Public IP address of data services instance"
  value       = vultr_instance.data_services.main_ip
}

output "data_services_id" {
  description = "Instance ID"
  value       = vultr_instance.data_services.id
}

output "firewall_group_id" {
  description = "Firewall group ID"
  value       = vultr_firewall_group.data_services.id
}

output "ssh_command" {
  description = "SSH command to connect to data services"
  value       = "ssh -i data_services_ssh_key root@${vultr_instance.data_services.main_ip}"
}

output "rippled_api_endpoint" {
  description = "rippled API node RPC endpoint"
  value       = "http://${vultr_instance.data_services.main_ip}:51234"
}

output "rippled_api_ws_endpoint" {
  description = "rippled API node WebSocket endpoint"
  value       = "ws://${vultr_instance.data_services.main_ip}:6005"
}

output "rippled_history_ws_endpoint" {
  description = "rippled Full-History WebSocket endpoint (internal)"
  value       = "ws://${vultr_instance.data_services.main_ip}:6006"
}

output "postgresql_connection" {
  description = "PostgreSQL connection string (internal)"
  value       = "postgresql://localhost:5432/lucendex"
  sensitive   = true
}
