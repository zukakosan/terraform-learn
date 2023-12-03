output "vnet_id" {
  value = azurerm_virtual_network.workload.id
}

output "jumpbox_subnet_id" {
  value = azurerm_subnet.jumpbox.id
}

output "pe_subnet_id" {
  value = azurerm_subnet.pe.id
}