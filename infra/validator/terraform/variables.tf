# Contabo API Authentication
variable "contabo_client_id" {
  description = "Contabo OAuth2 Client ID"
  type        = string
  sensitive   = true
}

variable "contabo_client_secret" {
  description = "Contabo OAuth2 Client Secret"
  type        = string
  sensitive   = true
}

variable "contabo_api_user" {
  description = "Contabo API User (email address)"
  type        = string
  sensitive   = true
}

variable "contabo_api_password" {
  description = "Contabo API Password"
  type        = string
  sensitive   = true
}

# Instance Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Contabo region for validator deployment"
  type        = string
  default     = "EU" # Frankfurt, Germany - closest to Malta
  
  # Available regions:
  # EU - Frankfurt, Germany
  # US-central - St. Louis, USA
  # US-east - New York, USA
  # US-west - Seattle, USA
  # SIN - Singapore
  # UK - London
  # AUS - Sydney
  # JPN - Tokyo
  # IND - India
}

variable "instance_plan" {
  description = "Contabo product ID (VPS plan)"
  type        = string
  default     = "V97" # VPS 30 NVMe: 8 vCPU, 24GB RAM, 200GB NVMe - €11.20/month
  
  # Available validator plans:
  # V91 - VPS 10 NVMe: 4 vCPU, 8GB RAM, 75GB NVMe (~€6/month)
  # V97 - VPS 30 NVMe: 8 vCPU, 24GB RAM, 200GB NVMe (~€11.20/month) [RECOMMENDED]
  # V100 - VPS 40 NVMe: 10 vCPU, 30GB RAM, 250GB NVMe (~€17/month)
}

variable "image_id" {
  description = "Contabo image ID"
  type        = string
  default     = "afecbb85-e2fc-46f0-9684-b46b1faf00bb" # Ubuntu 22.04 LTS
}

variable "period" {
  description = "Billing period in months (1, 3, 6, or 12)"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([1, 3, 6, 12], var.period)
    error_message = "Period must be 1, 3, 6, or 12 months."
  }
}

variable "default_user" {
  description = "Default user for SSH access"
  type        = string
  default     = "root"
  
  validation {
    condition     = contains(["root", "admin"], var.default_user)
    error_message = "Default user must be either 'root' or 'admin'."
  }
}

# SSH Configuration (Optional)
# Note: SSH keys in Contabo must be pre-created via the Secrets API
# and referenced by their secretId
variable "ssh_key_secret_id" {
  description = "Contabo secret ID for SSH public key"
  type        = number
  default     = null
}

variable "root_password_secret_id" {
  description = "Contabo secret ID for root password"
  type        = number
  default     = null
}

# Optional Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    project = "lucendex"
    role    = "xrpl-validator"
  }
}
