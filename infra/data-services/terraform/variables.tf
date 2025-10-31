variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (production, staging, etc.)"
  type        = string
  default     = "production"
}

variable "instance_plan" {
  description = "Vultr instance plan ID"
  type        = string
  # vc2-6c-16gb: 6 vCPU, 16GB RAM, 320GB SSD - $96/mo
  default     = "vc2-6c-16gb"
}

variable "region" {
  description = "Vultr region"
  type        = string
  # Frankfurt (close to Malta)
  default     = "fra"
}

variable "os_id" {
  description = "Operating system ID"
  type        = string
  # Ubuntu 22.04 LTS
  default     = "1743"
}

variable "admin_ip" {
  description = "Admin IP address for SSH access (leave empty for 0.0.0.0/0)"
  type        = string
  default     = ""
}

variable "postgres_password" {
  description = "PostgreSQL superuser password"
  type        = string
  sensitive   = true
}

variable "indexer_db_password" {
  description = "PostgreSQL indexer_rw role password"
  type        = string
  sensitive   = true
}

variable "router_db_password" {
  description = "PostgreSQL router_ro role password"
  type        = string
  sensitive   = true
}

variable "api_db_password" {
  description = "PostgreSQL api_ro role password"
  type        = string
  sensitive   = true
}
