
resource "azurerm_resource_group" "aoai" {
  name     = var.rg_name
  location = var.location
}

module "vnet" {
  source = "../../vnet"
  resource_group_name = azurerm_resource_group.aoai.name
  location = var.location
  vnet_name = var.vnet_name
  address_space = var.address_space
  jumpbox_subnet_address_space = var.jumpbox_subnet_address_space
  pe_subnet_address_space = var.pe_subnet_address_space
}