variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Vultr region for validator deployment"
  type        = string
  default     = "ams" # Amsterdam
  
  # Available regions:
  # ams - Amsterdam
  # atl - Atlanta
  # cdg - Paris
  # dfw - Dallas
  # ewr - New Jersey
  # fra - Frankfurt
  # lhr - London
  # lax - Los Angeles
  # nrt - Tokyo
  # ord - Chicago
  # sea - Seattle
  # sgp - Singapore
  # syd - Sydney
}

variable "instance_plan" {
  description = "Vultr instance plan"
  type        = string
  default     = "vc2-4c-8gb" # 4 vCPU, 8GB RAM, 160GB SSD
  
  # Available plans:
  # vc2-1c-2gb  - 1 vCPU, 2GB RAM, 55GB SSD   (~$12/mo)
  # vc2-2c-4gb  - 2 vCPU, 4GB RAM, 80GB SSD   (~$24/mo)
  # vc2-4c-8gb  - 4 vCPU, 8GB RAM, 160GB SSD  (~$48/mo) [RECOMMENDED]
  # vc2-6c-16gb - 6 vCPU, 16GB RAM, 320GB SSD (~$96/mo)
}

variable "os_id" {
  description = "Operating system ID"
  type        = number
  default     = 1743 # Ubuntu 22.04 LTS x64
}

variable "admin_ip" {
  description = "Admin IP address for SSH access (leave empty for any)"
  type        = string
  default     = ""
  
  # To restrict SSH to your IP:
  # admin_ip = "203.0.113.42" # Your IP address
}

variable "validator_domain" {
  description = "Optional domain name for validator"
  type        = string
  default     = ""
}

variable "enable_ipv6" {
  description = "Enable IPv6 support"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    project = "lucendex"
    role    = "xrpl-validator"
  }
}
