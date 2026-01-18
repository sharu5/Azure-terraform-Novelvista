output "public_vm_ips" {
  value = { for k, vm in azurerm_linux_virtual_machine.public_vm : k => azurerm_public_ip.public_vm_ip[k].ip_address }
}

output "private_vm_private_ips" {
  value = { for k, nic in azurerm_network_interface.private_nic : k => nic.private_ip_address }
}

output "public_nsg_id" {
  value = azurerm_network_security_group.public_nsg.id
}

output "private_nsg_id" {
  value = azurerm_network_security_group.private_nsg.id
}

output "ssh_connection_command" {
  value = { for k, vm in azurerm_linux_virtual_machine.public_vm :
    k => "ssh ${vm.admin_username}@${azurerm_public_ip.public_vm_ip[k].ip_address}"
  }
}