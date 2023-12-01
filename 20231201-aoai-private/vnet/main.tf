variable "resource_group_name" {}
variable "location" {}
variable "address_space" {}
variable "vnet_name" {}
variable "jumpbox_subnet_address_space" {}
variable "pe_subnet_address_space" {}

resource "azurerm_virtual_network" "workload" {
  resource_group_name = var.resource_group_name
  location = var.location
  name = var.vnet_name
  address_space = [var.address_space]
}

# Create Jumpbox Subnet
resource "azurerm_subnet" "jumpbox" {
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.workload.name
  name = "subnet-jumpbox"
  address_prefixes = [var.jumpbox_subnet_address_space]
}

resource "azurerm_network_security_group" "jumpbox" {
  name = "nsg-jumpbox"
  location = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id = azurerm_subnet.jumpbox.id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

# Create Private Endpoint Subnet
resource "azurerm_subnet" "pe" {
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.workload.name
  name = "subnet-pe"
  address_prefixes = [var.pe_subnet_address_space]
}

resource "azurerm_network_security_group" "pe" {
  name = "nsg-pe"
  location = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id = azurerm_subnet.pe.id
  network_security_group_id = azurerm_network_security_group.pe.id
}
