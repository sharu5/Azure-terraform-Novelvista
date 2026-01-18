# Generate SSH key if file doesn't exist
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  # Try to read SSH key from file, fallback to generated key
  ssh_public_key = try(
    file(pathexpand(var.vm_config.ssh_public_key_path)),
    tls_private_key.ssh_key.public_key_openssh
  )

  ssh_private_key = try(
    file(pathexpand(replace(var.vm_config.ssh_public_key_path, ".pub", ""))),
    tls_private_key.ssh_key.private_key_openssh
  )

  # Common tags for compute resources
  compute_tags = merge(var.tags, {
    Component = "Compute"
  })
}
# ---------- PUBLIC SUBNET NSG ----------
resource "azurerm_network_security_group" "public_nsg" {
  name                = "public-subnet-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { Tier = "Public" })
}

# NSG Rules for Public Subnet
resource "azurerm_network_security_rule" "public_inbound_rules" {
  for_each = {
    ssh = {
      name                       = "AllowSSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.my_public_ip
      destination_address_prefix = "*"
    }
    http = {
      name                       = "AllowHTTP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "0.0.0.0/0"
      destination_address_prefix = "*"
    }
    https = {
      name                       = "AllowHTTPS"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "0.0.0.0/0"
      destination_address_prefix = "*"
    }
    app = {
      name                       = "AllowApp"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.app_config.port
      source_address_prefix      = "0.0.0.0/0"
      destination_address_prefix = "*"
    }
  }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public_nsg.name
}

# Allow public VMs to talk to private VMs
resource "azurerm_network_security_rule" "public_to_private" {
  name                        = "AllowToPrivateSubnet"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = var.subnets_config.private.cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public_nsg.name
}

# ---------- PRIVATE SUBNET NSG ----------
resource "azurerm_network_security_group" "private_nsg" {
  name                = "private-subnet-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { Tier = "Private" })
}

# NSG Rules for Private Subnet
resource "azurerm_network_security_rule" "private_inbound_rules" {
  for_each = {
    ssh-from-public = {
      name                       = "AllowSSHFromPublic"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.subnets_config.public.cidr
      destination_address_prefix = "*"
    }
    app-from-public = {
      name                       = "AllowAppFromPublic"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.app_config.port
      source_address_prefix      = var.subnets_config.public.cidr
      destination_address_prefix = "*"
    }
  }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# Allow private VMs to talk to database subnet
resource "azurerm_network_security_rule" "private_to_database" {
  name                        = "AllowToDatabase"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.3.0/24" # Database subnet CIDR
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# Allow response from database
resource "azurerm_network_security_rule" "database_response" {
  name                        = "AllowDatabaseResponse"
  priority                    = 210
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.3.0/24" # Database subnet CIDR
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# ---------- PUBLIC VMs ----------
resource "azurerm_public_ip" "public_vm_ip" {
  for_each = { for vm in var.vm_config.public_vms : vm.name => vm }

  name                = "${each.value.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.tags, { VM = each.value.name, Tier = "Public" })
}

resource "azurerm_network_interface" "public_nic" {
  for_each = { for vm in var.vm_config.public_vms : vm.name => vm }

  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { VM = each.value.name, Tier = "Public" })

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnets_config.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_vm_ip[each.key].id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "public_nic_nsg" {
  for_each = { for vm in var.vm_config.public_vms : vm.name => vm }

  network_interface_id      = azurerm_network_interface.public_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_linux_virtual_machine" "public_vm" {
  for_each = { for vm in var.vm_config.public_vms : vm.name => vm }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.size
  admin_username      = each.value.admin_user
  tags                = merge(var.tags, { VM = each.value.name, Tier = "Public", Role = "Web" })

  network_interface_ids = [azurerm_network_interface.public_nic[each.key].id]

  admin_ssh_key {
    username   = each.value.admin_user
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Automatically deploy application
  custom_data = base64encode(templatefile("${path.module}/deploy_app.sh", {
    app_name    = var.app_config.name
    app_port    = var.app_config.port
    environment = var.app_config.environment
    role        = "web"
  }))
}

# ---------- PRIVATE VMs ----------
resource "azurerm_network_interface" "private_nic" {
  for_each = { for vm in var.vm_config.private_vms : vm.name => vm }

  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { VM = each.value.name, Tier = "Private" })

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnets_config.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "private_nic_nsg" {
  for_each = { for vm in var.vm_config.private_vms : vm.name => vm }

  network_interface_id      = azurerm_network_interface.private_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_linux_virtual_machine" "private_vm" {
  for_each = { for vm in var.vm_config.private_vms : vm.name => vm }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.size
  admin_username      = each.value.admin_user
  tags                = merge(var.tags, { VM = each.value.name, Tier = "Private", Role = "App" })

  network_interface_ids = [azurerm_network_interface.private_nic[each.key].id]

  admin_ssh_key {
    username   = each.value.admin_user
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Automatically deploy application
  custom_data = base64encode(templatefile("${path.module}/deploy_app.sh", {
    app_name    = var.app_config.name
    app_port    = var.app_config.port
    environment = var.app_config.environment
    role        = "app"
  }))
}