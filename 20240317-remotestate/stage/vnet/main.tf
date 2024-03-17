terraform {
  required_providers {
	azurerm = {
		source = "hashicorp/azurerm"
		version = "~>3.0"
	}
  }
  backend "azurerm" {
	resource_group_name = "20240317-state-mgmt"
	storage_account_name = "strgstatemgmt"
	container_name = "tfstatestg"
	key = "vnet.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  location = "japaneast"
  resource_group_name = "20240317-stg"
}

resource "azurerm_resource_group" "stg" {
  name = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "hub" {
  name = "vnet-hub"
  location = azurerm_resource_group.stg.location
  resource_group_name = azurerm_resource_group.stg.name
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vm" {
  name = "subnet-vm"
  resource_group_name = azurerm_resource_group.stg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "hub" {
  name = "nsg-hub"
  resource_group_name = azurerm_resource_group.stg.name
  location = azurerm_resource_group.stg.location
}

resource "azurerm_subnet_network_security_group_association" "hub-vm" {
  subnet_id = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.hub.id
}