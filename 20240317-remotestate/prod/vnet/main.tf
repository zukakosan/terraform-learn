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
	container_name = "tfstateprd"
	key = "vnet.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  location = "japaneast"
  resource_group_name = "20240317-prd"
}

resource "azurerm_resource_group" "prd" {
  name = local.resource_group_name
  location = local.location
}

# resource "azurerm_virtual_network" "hub" {
#   name = "vnet-hub"
#   location = azurerm_resource_group.prd.location
#   resource_group_name = azurerm_resource_group.prd.name
#   address_space = ["10.0.0.0/16"]
# }

# resource "azurerm_subnet" "vm" {
#   name = "subnet-vm"
#   resource_group_name = azurerm_resource_group.prd.name
#   virtual_network_name = azurerm_virtual_network.hub.name
#   address_prefixes = ["10.0.1.0/24"]
# }

# resource "azurerm_network_security_group" "hub" {
#   name = "nsg-hub"
#   resource_group_name = azurerm_resource_group.prd.name
#   location = azurerm_resource_group.prd.location
# }

# resource "azurerm_subnet_network_security_group_association" "hub-vm" {
#   subnet_id = azurerm_subnet.vm.id
#   network_security_group_id = azurerm_network_security_group.hub.id
# }

# 環境ごとに共通化できるようにモジュール呼びだし
module "vnet" {
  source = "../../modules/vnet"
  resource_group_name = resource.azurerm_resource_group.prd.name
  location = resource.azurerm_resource_group.prd.location
  vnet_name = "vnet-hub"
  address_prefixes = ["10.0.0.0/16"]
  subnet_name = "subnet-vm"
  subnet_address_prefixes = [ "10.0.0.0/24" ]
}