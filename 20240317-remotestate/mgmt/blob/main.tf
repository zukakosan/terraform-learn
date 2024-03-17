terraform {
  required_version = "~>1.0"
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~>3.0"
    }
    random = {
        source = "hashicorp/random"
        version = "~>3.0"
    }
  }
  backend "local" {
    path = "../state/terraform.tfstate"
  }
}

provider "azurerm" {
features {}
}

resource "azurerm_resource_group" "tfstate" {
  name = "20240317-state-mgmt"
  location = "japaneast"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "strgstatemgmt"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state-stg" {
  name = "tfstatestg"
  storage_account_name = azurerm_storage_account.tfstate.name
}

resource "azurerm_storage_container" "state-prd" {
  name = "tfstateprd"
  storage_account_name = azurerm_storage_account.tfstate.name
}