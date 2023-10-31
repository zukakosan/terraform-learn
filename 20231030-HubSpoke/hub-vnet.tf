/*
local values
*/
locals {
  hub_address_space      = ["10.0.0.0/16"]
#   spoke001_address_space = ["10.10.0.0/16"]
#   spoke002_address_space = ["10.20.0.0/16"]
  spoke_subnet_count     = 2
}


# Create Resource Group for Hub resources
resource "azurerm_resource_group" "rg_hub" {
  name     = "${var.rg_prefix}-hub-rg"
  location = var.rg_location
}

# Create Resource Group for Spoke resources
resource "azurerm_resource_group" "rg_spoke" {
  name     = "${var.rg_prefix}-spoke-rg"
  location = var.rg_location
}

/*
Hub Resources
*/

# Create Hub Virtual Network
resource "azurerm_virtual_network" "hub_vnet" {
  resource_group_name = azurerm_resource_group.rg_hub.name
  name                = "vnet-hub"
  location            = azurerm_resource_group.rg_hub.location
  address_space       = local.hub_address_space
}

# Create Hub Subnet
resource "azurerm_subnet" "hub_subnets" {
  for_each             = { for i in var.hub_subnets : i.name => i }
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [each.value.address_prefixes]
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg_hub" {
  name                = "nsg-hub"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
}

# Associate Network Security Group to Hub Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_hub_association" {
  # for_each = { for i in var.hub_subnets : i.name => i }
  network_security_group_id = azurerm_network_security_group.nsg_hub.id
  subnet_id                 = azurerm_subnet.hub_subnets[var.hub_subnets[1].name].id
}

# Create Azure Firewall Public IP
resource "azurerm_public_ip" "azfw_hub_pip" {
  name                = "azfw-hub-pip"
  resource_group_name = azurerm_resource_group.rg_hub.name
  location            = azurerm_resource_group.rg_hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Azure Firewall Policy
resource "azurerm_firewall_policy" "azfw_hub_policy" {
  name                     = "azfw-hub-policy"
  resource_group_name      = azurerm_resource_group.rg_hub.name
  location                 = azurerm_resource_group.rg_hub.location
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
}

# Create Azure Firewall Policy Rule Collection Group (Network Rule)
resource "azurerm_firewall_policy_rule_collection_group" "azfw_netrule_collection" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.azfw_hub_policy.id
  priority           = 200
  network_rule_collection {
    name     = "DefaultNetworkRuleCollection"
    action   = "Allow"
    priority = 200
    rule {
      name                  = "allow-east-west-traffic"
      protocols             = ["Any"]
      source_addresses      = [element(local.spoke001_address_space, 0), element(local.spoke002_address_space, 0)]
      destination_ports     = ["*"]
      destination_addresses = [element(local.spoke001_address_space, 0), element(local.spoke002_address_space, 0)]
    }
  }
}

# Create Azure Firewall in Hub
resource "azurerm_firewall" "azfw_hub" {
  name                = "azfw-hub"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "azfw-ipconfig1"
    subnet_id            = azurerm_subnet.hub_subnets["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.azfw_hub_pip.id
  }
  firewall_policy_id = azurerm_firewall_policy.azfw_hub_policy.id
}

/*
 Create Jumpbox Virtual Machine in Hub
*/

# Create Network Interface for Spoke-001 Virtual Machine
resource "azurerm_network_interface" "vm_jumpbox_nic" {
  name                = "vm-jumpbox-nic"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.hub_subnets[var.hub_subnets[1].name].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Virtual Machine 
resource "azurerm_linux_virtual_machine" "vm_jumpbox" {
  name                            = "vm-jumpbox"
  computer_name                   = "vm-jumpbox"
  resource_group_name             = azurerm_resource_group.rg_hub.name
  location                        = azurerm_resource_group.rg_hub.location
  size                            = "Standard_B1s"
  disable_password_authentication = false
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  network_interface_ids           = [azurerm_network_interface.vm_jumpbox_nic.id]
  os_disk {
    name                 = "vm-jumpbox-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Create Azure Firewall Policy Rule Collection Group (DNAT Rule)
resource "azurerm_firewall_policy_rule_collection_group" "azfw_natrule_collection" {
  name               = "DefaultDnatRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.azfw_hub_policy.id
  priority           = 200
  nat_rule_collection {
    name     = "DefaultDnatRuleCollection"
    priority = 200
    action   = "Dnat"
    rule {
      name                = "nat-jumpbox"
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.azfw_hub_pip.ip_address
      destination_ports   = ["22"]
      translated_address  = azurerm_network_interface.vm_jumpbox_nic.ip_configuration[0].private_ip_address
      translated_port     = "22"
      protocols           = ["TCP"]
    }
  }
}
