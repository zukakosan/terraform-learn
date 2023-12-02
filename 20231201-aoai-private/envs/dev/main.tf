# Create Resource Group
resource "azurerm_resource_group" "aoai" {
  name     = var.rg_name
  location = var.location
}

# Create Virtual Network for jumpbox and private endpoint of AOAI
module "vnet" {
  source = "../../vnet"
  resource_group_name = azurerm_resource_group.aoai.name
  location = var.location
  vnet_name = var.vnet_name
  address_space = var.address_space
  jumpbox_subnet_address_space = var.jumpbox_subnet_address_space
  pe_subnet_address_space = var.pe_subnet_address_space
  client_ip = var.client_ip
}

# Create jumpbox to access AOAI in private
module "vm_windows"{
  source = "../../vm"
  resource_group_name = azurerm_resource_group.aoai.name
  location = var.location
  vm_suffix = var.env
  # use subnet_id from vnet module output
  subnet_id = module.vnet.jumpbox_subnet_id
  admin_username = var.admin_username
  admin_password = var.admin_password
}

# Create AOAI
resource "random_id" "aoai" {
  byte_length = 4
}

module "aoai" {
  source = "../../aoai"
  resource_group_name = azurerm_resource_group.aoai.name
  location = var.location
  suffix = var.env
  vnet_id = module.vnet.vnet_id
  subnet_id = module.vnet.pe_subnet_id
  random_id = random_id.aoai.hex
}