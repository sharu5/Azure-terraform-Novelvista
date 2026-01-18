# Database Server Information
output "database_server_name" {
  description = "Name of the database server"
  value       = var.database_config.server_name
}

output "database_name" {
  description = "Name of the database"
  value       = var.database_config.database_name
}

output "database_engine" {
  description = "Type of database engine deployed"
  value       = var.database_config.engine
}

# Connection Information
output "database_fqdn" {
  description = "Fully qualified domain name of the database server"
  value = var.database_config.engine == "mysql" ? (
    try(azurerm_mysql_flexible_server.mysql[0].fqdn, "")
    ) : (
    try(azurerm_postgresql_flexible_server.postgres[0].fqdn, "")
  )
}

output "database_host" {
  description = "Database host address"
  value = var.database_config.engine == "mysql" ? (
    try(azurerm_mysql_flexible_server.mysql[0].fqdn, "")
    ) : (
    try(azurerm_postgresql_flexible_server.postgres[0].fqdn, "")
  )
}

output "database_port" {
  description = "Database port number"
  value       = var.database_config.engine == "mysql" ? 3306 : 5432
}

# Resource IDs
output "database_server_id" {
  description = "Resource ID of the database server"
  value = var.database_config.engine == "mysql" ? (
    try(azurerm_mysql_flexible_server.mysql[0].id, "")
    ) : (
    try(azurerm_postgresql_flexible_server.postgres[0].id, "")
  )
}

output "database_id" {
  description = "Resource ID of the database"
  value = var.database_config.engine == "mysql" ? (
    try(azurerm_mysql_flexible_database.mysql_database[0].id, "")
    ) : (
    try(azurerm_postgresql_flexible_server_database.postgres_database[0].id, "")
  )
}

# Connection Strings (Sensitive)
output "mysql_connection_string" {
  description = "MySQL connection string (only for MySQL)"
  value = var.database_config.engine == "mysql" ? (
    "mysql://${var.database_config.admin_username}:${var.database_config.admin_password}@${try(azurerm_mysql_flexible_server.mysql[0].fqdn, "")}/${var.database_config.database_name}"
  ) : null
  sensitive = true
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string (only for PostgreSQL)"
  value = var.database_config.engine == "postgresql" ? (
    "postgresql://${var.database_config.admin_username}:${var.database_config.admin_password}@${try(azurerm_postgresql_flexible_server.postgres[0].fqdn, "")}/${var.database_config.database_name}?sslmode=require"
  ) : null
  sensitive = true
}

output "connection_string" {
  description = "Generic connection string (auto-detects engine)"
  value = var.database_config.engine == "mysql" ? (
    "mysql://${var.database_config.admin_username}:${var.database_config.admin_password}@${try(azurerm_mysql_flexible_server.mysql[0].fqdn, "")}/${var.database_config.database_name}"
    ) : (
    "postgresql://${var.database_config.admin_username}:${var.database_config.admin_password}@${try(azurerm_postgresql_flexible_server.postgres[0].fqdn, "")}/${var.database_config.database_name}?sslmode=require"
  )
  sensitive = true
}

# Configuration Details
output "admin_username" {
  description = "Database administrator username"
  value       = var.database_config.admin_username
  sensitive   = true
}

output "database_version" {
  description = "Database version"
  value       = var.database_config.version
}

output "database_sku" {
  description = "Database SKU/Size"
  value       = var.database_config.sku_name
}

output "database_storage_gb" {
  description = "Database storage size in GB"
  value       = var.database_config.storage_gb
}

# Network Information
output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = var.network_config.subnet_id
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value = var.database_config.engine == "mysql" ? (
    try(azurerm_private_dns_zone.mysql[0].id, "")
    ) : (
    try(azurerm_private_dns_zone.postgres[0].id, "")
  )
}

# Security Information
output "allowed_app_subnet_cidr" {
  description = "CIDR block allowed to access the database"
  value       = var.allowed_app_subnet_cidr
}

# Status Information
output "database_status" {
  description = "Database deployment status"
  value = var.database_config.engine == "mysql" ? (
    try(azurerm_mysql_flexible_server.mysql[0].id != "" ? "MySQL deployed" : "Not deployed", "Not deployed")
    ) : (
    try(azurerm_postgresql_flexible_server.postgres[0].id != "" ? "PostgreSQL deployed" : "Not deployed", "Not deployed")
  )
}

# Firewall Rule Information
output "firewall_rule_name" {
  description = "Name of the firewall rule"
  value       = "allow-app-subnet"
}

# Tags
output "database_tags" {
  description = "Tags applied to database resources"
  value       = var.tags
}