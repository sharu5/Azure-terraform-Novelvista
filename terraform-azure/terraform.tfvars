# Azure Configuration
subscription_id                 = "your susbcription -id"
resource_group_name             = "azureskf-T"
resource_provider_registrations = "none"
location                        = "eastus"
vnet_name                       = "three-tier-vnet"

# Core Configuration
vnet_address_space = ["192.168.0.0/16"]

# Tags
tags = {
  Environment = "Production"
  Application = "ThreeTierApp"
  ManagedBy   = "Terraform"
  CostCenter  = "IT"
}

# Subnets Configuration
subnets = {
  "public" = {
    name              = "public-subnet"
    address_prefixes  = ["192.168.1.0/24"]
    service_endpoints = []
  }
  "private" = {
    name              = "private-subnet"
    address_prefixes  = ["192.168.2.0/24"]
    service_endpoints = []
  }
  "database" = {
    name              = "database-subnet"
    address_prefixes  = ["192.168.3.0/24"]
    service_endpoints = ["Microsoft.Sql"]
  }
}

# Compute Configuration
vm_config = {
  public_vms = [
    {
      name       = "web-vm-01"
      size       = "Standard_B2s"
      admin_user = "adminuser"
    }
  ]
  private_vms = [
    {
      name       = "app-vm-01"
      size       = "Standard_B2s"
      admin_user = "adminuser"
    }
  ]
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
}

# Application Configuration
app_config = {
  name        = "myapp"
  port        = 5000
  environment = "production"
}

# Database Configuration
database_config = {
  engine                = "mysql" # or "postgresql"
  server_name           = "app-mysql-server"
  database_name         = "appdb"
  admin_username        = "dbadmin"
  admin_password        = "SecurePassword123!"
  sku_name              = "GP_Standard_D2ds_v4"
  storage_gb            = 32
  version               = "8.0.21"
  backup_retention_days = 7
}