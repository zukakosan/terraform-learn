# terraform {
#   required_providers {
# 	azurerm = {
# 		source = "hashicorp/azurerm"
# 		version = "~>3.0"
# 	}
#   }
#   backend "azurerm" {
# 	resource_group_name = "20240317-state-mgmt"
# 	storage_account_name = "strgstatemgmt"
# 	container_name = "tfstatestg"
# 	key = "vnet.tfstate"
#   }
# }

provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "hub" {
  name = var.vnet_name
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.address_prefixes
}

resource "azurerm_subnet" "vm" {
  name = var.subnet_name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  # ここ配列いける？
  address_prefixes = var.subnet_address_prefixes
}

resource "azurerm_network_security_group" "hub" {
  name = "nsg-${var.vnet_name}"
  resource_group_name = var.resource_group_name
  location = var.location
}

resource "azurerm_subnet_network_security_group_association" "hub-subnet" {
  subnet_id = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.hub.id
}