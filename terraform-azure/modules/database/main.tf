# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql" {
  count = var.database_config.engine == "mysql" ? 1 : 0

  name                   = var.database_config.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.database_config.admin_username
  administrator_password = var.database_config.admin_password
  sku_name               = var.database_config.sku_name
  version                = var.database_config.version
  zone                   = var.zone
  tags                   = merge(var.tags, { Component = "Database", Engine = "MySQL" })

  storage {
    size_gb = var.database_config.storage_gb
    iops    = var.iops
  }

  backup_retention_days        = var.database_config.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  delegated_subnet_id = var.network_config.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql[0].id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.vnet_link]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  count = var.database_config.engine == "postgresql" ? 1 : 0

  name                   = var.database_config.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.database_config.admin_username
  administrator_password = var.database_config.admin_password
  sku_name               = var.database_config.sku_name
  version                = var.database_config.version
  zone                   = var.zone
  tags                   = merge(var.tags, { Component = "Database", Engine = "PostgreSQL" })

  storage_mb = var.database_config.storage_gb * 1024

  backup_retention_days        = var.database_config.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  delegated_subnet_id = var.network_config.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres[0].id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.vnet_link_postgres]
}

# Private DNS Zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  count = var.database_config.engine == "mysql" ? 1 : 0

  name                = var.dns_zone_names.mysql
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { Component = "DNS" })
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  count = var.database_config.engine == "postgresql" ? 1 : 0

  name                = var.dns_zone_names.postgres
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { Component = "DNS" })
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count = var.database_config.engine == "mysql" ? 1 : 0

  name                  = "${var.database_config.server_name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = var.network_config.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = merge(var.tags, { Component = "DNS" })
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_postgres" {
  count = var.database_config.engine == "postgresql" ? 1 : 0

  name                  = "${var.database_config.server_name}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = var.network_config.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = merge(var.tags, { Component = "DNS" })
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "mysql_database" {
  count = var.database_config.engine == "mysql" ? 1 : 0

  name                = var.database_config.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql[0].name
  charset             = var.mysql_charset
  collation           = var.mysql_collation
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "postgres_database" {
  count = var.database_config.engine == "postgresql" ? 1 : 0

  name      = var.database_config.database_name
  server_id = azurerm_postgresql_flexible_server.postgres[0].id
  charset   = var.postgres_charset
  collation = var.postgres_collation
}

# Firewall rule for MySQL - allow only from application subnet
resource "azurerm_mysql_flexible_server_firewall_rule" "mysql_app_subnet" {
  count               = var.database_config.engine == "mysql" ? 1 : 0
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql[0].name
  name                = "allow-app-subnet"
  start_ip_address    = cidrhost(var.allowed_app_subnet_cidr, 0)
  end_ip_address      = cidrhost(var.allowed_app_subnet_cidr, 255)
}

# Firewall rule for PostgreSQL - allow only from application subnet
resource "azurerm_postgresql_flexible_server_firewall_rule" "postgres_app_subnet" {
  count = var.database_config.engine == "postgresql" ? 1 : 0

  name             = "allow-app-subnet"
  server_id        = azurerm_postgresql_flexible_server.postgres[0].id
  start_ip_address = cidrhost(var.allowed_app_subnet_cidr, 0)
  end_ip_address   = cidrhost(var.allowed_app_subnet_cidr, 255)
}