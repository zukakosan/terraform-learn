run "validate_subnet_private" {
	command = plan
	assert {
		condition = azurerm_virtual_network.test.location == "japaneast"
		error_message = "${azurerm_virtual_network.test.name} のリージョンが適切ではありません"
	}
}