/*
output "vnet_id" {
  value       = module.vnet.vnet_id
  description = "Virtual Network ID"
}

output "subnet_ids" {
  value       = module.subnet.subnet_ids
  description = "Map of subnet IDs"
}

output "public_vm_ips" {
  value       = module.compute.public_vm_ips
  description = "Public IP addresses of public VMs"
}

output "database_fqdn" {
  value       = module.database.database_fqdn
  description = "Database fully qualified domain name"
  sensitive   = true
}

output "database_connection_string" {
  value       = module.database.connection_string
  description = "Database connection string for application"
  sensitive   = true
}

output "ssh_connection_command" {
  value       = module.compute.ssh_connection_command
  description = "SSH command to connect to public VM"
}

output "application_url" {
  value       = "http://${module.compute.public_vm_ips[0]}:${var.app_config.port}"
  description = "URL to access the application"
}

# VNet Information
output "vnet_id" {
  value       = module.vnet.vnet_id
  description = "Virtual Network ID"
}

output "subnet_ids" {
  value       = module.subnet.subnet_ids
  description = "Map of subnet IDs"
}

# Compute Information
output "public_vm_ips" {
  value       = module.compute.public_vm_ips
  description = "Public IP addresses of all public VMs"
}

output "private_vm_ips" {
  value       = module.compute.private_vm_private_ips
  description = "Private IP addresses of all private VMs"
}

output "ssh_connection_commands" {
  value       = module.compute.ssh_connection_commands
  description = "SSH commands to connect to public VMs"
}

# Application URLs - Fixed: Access by key name, not index
output "application_urls" {
  value = {
    for vm_name, ip in module.compute.public_vm_ips :
    vm_name => "http://${ip}:${var.app_config.port}"
  }
  description = "URLs to access each application instance"
}

# Single application URL (first VM) - Optional
output "application_url" {
  value = length(module.compute.public_vm_ips) > 0 ? (
    "http://${values(module.compute.public_vm_ips)[0]}:${var.app_config.port}"
  ) : null
  description = "URL to access the first application instance"
}
*/
# Database Information
output "database_fqdn" {
  value       = module.database.database_fqdn
  description = "Database fully qualified domain name"
}

output "database_connection_string" {
  value       = module.database.connection_string
  description = "Database connection string for application"
  sensitive   = true
}

output "database_port" {
  value       = module.database.database_port
  description = "Database port number"
}

# SSH Key Information
output "generated_ssh_key" {
  value       = try(module.compute.generated_ssh_private_key, null)
  description = "Generated SSH private key (if file not found)"
  sensitive   = true
}

# Deployment Summary
output "deployment_summary" {
  value = {
    vnet_name   = var.vnet_name
    location    = var.location
    public_vms  = [for vm in var.vm_config.public_vms : vm.name]
    private_vms = [for vm in var.vm_config.private_vms : vm.name]
    database    = var.database_config.server_name
    application = var.app_config.name
    environment = var.app_config.environment
  }
  description = "Summary of the deployed infrastructure"
}