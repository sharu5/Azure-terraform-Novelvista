output "subnet_ids" {
  value = { for k, subnet in azurerm_subnet.subnets : k => subnet.id }
}

output "subnet_names" {
  value = { for k, subnet in azurerm_subnet.subnets : k => subnet.name }
}