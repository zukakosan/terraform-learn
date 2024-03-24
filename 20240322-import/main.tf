resource "azurerm_resource_group" "test" {
  name     = "20240322-terraform-import"
  location = "japaneast"
}

resource "azurerm_virtual_network" "test" {
	name = "vnet-import"
	location = azurerm_resource_group.test.location
	resource_group_name = azurerm_resource_group.test.name
	address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "test" {
	name = "default"
	resource_group_name = azurerm_resource_group.test.name
	virtual_network_name = azurerm_virtual_network.test.name
	address_prefixes = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnet-001" {
	name = "subnet-001"
	resource_group_name = azurerm_resource_group.test.name
	virtual_network_name = azurerm_virtual_network.test.name
	address_prefixes = ["10.0.1.0/24"]
}