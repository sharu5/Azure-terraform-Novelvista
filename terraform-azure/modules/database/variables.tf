# Required Variables
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "network_config" {
  description = "Network configuration for database deployment"
  type = object({
    vnet_id     = string # Virtual Network ID
    subnet_id   = string # Database Subnet ID
    subnet_cidr = string # Database Subnet CIDR (e.g., "10.0.3.0/24")
  })
}

# Database Configuration
variable "database_config" {
  description = "Configuration for the database server"
  type = object({
    engine                = string # "mysql" or "postgresql"
    server_name           = string # Database server name
    database_name         = string # Database name
    admin_username        = string # Administrator username
    admin_password        = string # Administrator password
    sku_name              = string # SKU name (e.g., "GP_Standard_D2ds_v4")
    storage_gb            = number # Storage size in GB
    version               = string # Database version
    backup_retention_days = number # Backup retention in days
  })

  validation {
    condition     = contains(["mysql", "postgresql"], var.database_config.engine)
    error_message = "Database engine must be either 'mysql' or 'postgresql'."
  }

  validation {
    condition     = var.database_config.storage_gb >= 20 && var.database_config.storage_gb <= 16384
    error_message = "Storage size must be between 20 GB and 16384 GB."
  }

  validation {
    condition     = var.database_config.backup_retention_days >= 1 && var.database_config.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

# Security Configuration
variable "allowed_app_subnet_cidr" {
  description = "CIDR block of the application subnet (private subnet) allowed to access the database"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_app_subnet_cidr))
    error_message = "Value must be a valid CIDR notation (e.g., '10.0.2.0/24')."
  }
}

# Optional Variables with Defaults
variable "zone" {
  description = "Availability zone for the database server"
  type        = string
  default     = "1"
}

variable "iops" {
  description = "Input/output operations per second for MySQL storage (only for MySQL)"
  type        = number
  default     = 360
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup"
  type        = bool
  default     = false
}

# MySQL Specific Defaults
variable "mysql_charset" {
  description = "Character set for MySQL database"
  type        = string
  default     = "utf8mb4"
}

variable "mysql_collation" {
  description = "Collation for MySQL database"
  type        = string
  default     = "utf8mb4_unicode_ci"
}

# PostgreSQL Specific Defaults
variable "postgres_charset" {
  description = "Character set for PostgreSQL database"
  type        = string
  default     = "UTF8"
}

variable "postgres_collation" {
  description = "Collation for PostgreSQL database"
  type        = string
  default     = "en_US.utf8"
}

# DNS Configuration
variable "dns_zone_names" {
  description = "Private DNS zone names for MySQL and PostgreSQL"
  type = object({
    mysql    = string
    postgres = string
  })
  default = {
    mysql    = "private.mysql.database.azure.com"
    postgres = "private.postgres.database.azure.com"
  }
}