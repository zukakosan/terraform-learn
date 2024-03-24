check "vnet_location_check" {
  	assert {
		condition = azurerm_virtual_network.test.location == "eastus"
		error_message = "${azurerm_virtual_network.test.name} のリージョンが適切ではありません"
	}
}