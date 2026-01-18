# 1. Create Virtual Network
module "vnet" {
  source = "./modules/vnet"

  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  tags                = var.tags
}

# 2. Create Subnets (Public, Private, Database)
module "subnet" {
  source = "./modules/subnet"

  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  vnet_id             = module.vnet.vnet_id
  subnets             = var.subnets
  tags                = var.tags

  depends_on = [module.vnet]
}

# 3. Create VMs with Integrated NSGs - Your correct approach!
module "compute" {
  source = "./modules/compute"

  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  my_public_ip        = local.my_public_ip # Your IP: 119.8.27.186/32
  tags                = var.tags

  # Subnet configurations
  subnets_config = {
    public = {
      id   = module.subnet.subnet_ids["public"]
      cidr = var.subnets["public"].address_prefixes[0]
    }
    private = {
      id   = module.subnet.subnet_ids["private"]
      cidr = var.subnets["private"].address_prefixes[0]
    }
  }

  # VM configurations
  vm_config = var.vm_config

  # Application configuration
  app_config = var.app_config

  depends_on = [module.subnet]
}

# 4. Create Database in Database Subnet
module "database" {
  source = "./modules/database"

  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  tags                = var.tags

  # Network configuration
  network_config = {
    vnet_id     = module.vnet.vnet_id
    subnet_id   = module.subnet.subnet_ids["database"]
    subnet_cidr = var.subnets["database"].address_prefixes[0]
  }

  # Database configuration
  database_config = var.database_config

  # Allow connections from private subnet (where app VMs are)
  allowed_app_subnet_cidr = var.subnets["private"].address_prefixes[0]

  depends_on = [module.subnet, module.compute]
}