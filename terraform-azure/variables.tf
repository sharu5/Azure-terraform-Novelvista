# Core Infrastructure Variables
variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group"
  type        = string
}
variable "subscription_id" {
  type = string
}
variable "location" {
  type = string
}
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

# Subnets Configuration
variable "subnets" {
  description = "Configuration for all subnets"
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string))
  }))
}

# Compute Configuration
variable "vm_config" {
  description = "Configuration for Virtual Machines"
  type = object({
    public_vms = list(object({
      name       = string
      size       = string
      admin_user = string
    }))
    private_vms = list(object({
      name       = string
      size       = string
      admin_user = string
    }))
    ssh_public_key_path = string
  })
}

# Application Configuration
variable "app_config" {
  description = "Application specific configuration"
  type = object({
    name        = string
    port        = number
    environment = string
  })
}

# Database Configuration
variable "database_config" {
  description = "Configuration for database server"
  type = object({
    engine                = string # "mysql" or "postgresql"
    server_name           = string
    database_name         = string
    admin_username        = string
    admin_password        = string
    sku_name              = string
    storage_gb            = number
    version               = string
    backup_retention_days = number
  })
}

# Tags
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
// SSH Public Key Path
/*
variable "ssh_public_key_path" {
  type = string
}
*/

variable "resource_provider_registrations" {
  type = string
}