/*
local values
*/
# locals {
#   hub_address_space      = ["10.0.0.0/16"]
#   spoke001_address_space = ["10.10.0.0/16"]
#   spoke002_address_space = ["10.20.0.0/16"]
#   spoke_subnet_count     = 2
# }

# # Create Resource Group for Hub resources
# resource "azurerm_resource_group" "rg_hub" {
#   name     = "${var.rg_prefix}-hub-rg"
#   location = var.rg_location
# }

# # Create Resource Group for Spoke resources
# resource "azurerm_resource_group" "rg_spoke" {
#   name     = "${var.rg_prefix}-spoke-rg"
#   location = var.rg_location
# }

# /*
# Hub Resources
# */

# # Create Hub Virtual Network
# resource "azurerm_virtual_network" "hub_vnet" {
#   resource_group_name = azurerm_resource_group.rg_hub.name
#   name                = "vnet-hub"
#   location            = azurerm_resource_group.rg_hub.location
#   address_space       = local.hub_address_space
# }

# # Create Hub Subnet
# resource "azurerm_subnet" "hub_subnets" {
#   for_each             = { for i in var.hub_subnets : i.name => i }
#   name                 = each.value.name
#   resource_group_name  = azurerm_resource_group.rg_hub.name
#   virtual_network_name = azurerm_virtual_network.hub_vnet.name
#   address_prefixes     = [each.value.address_prefixes]
# }

# # Create Network Security Group
# resource "azurerm_network_security_group" "nsg_hub" {
#   name                = "nsg-hub"
#   location            = azurerm_resource_group.rg_hub.location
#   resource_group_name = azurerm_resource_group.rg_hub.name
# }

# # Associate Network Security Group to Hub Subnets
# resource "azurerm_subnet_network_security_group_association" "nsg_hub_association" {
#   # for_each = { for i in var.hub_subnets : i.name => i }
#   network_security_group_id = azurerm_network_security_group.nsg_hub.id
#   subnet_id                 = azurerm_subnet.hub_subnets[var.hub_subnets[1].name].id
# }

# # Create Azure Firewall Public IP
# resource "azurerm_public_ip" "azfw_hub_pip" {
#   name                = "azfw-hub-pip"
#   resource_group_name = azurerm_resource_group.rg_hub.name
#   location            = azurerm_resource_group.rg_hub.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Create Azure Firewall Policy
# resource "azurerm_firewall_policy" "azfw_hub_policy" {
#   name                     = "azfw-hub-policy"
#   resource_group_name      = azurerm_resource_group.rg_hub.name
#   location                 = azurerm_resource_group.rg_hub.location
#   sku                      = "Standard"
#   threat_intelligence_mode = "Alert"
# }

# # Create Azure Firewall Policy Rule Collection Group (Network Rule)
# resource "azurerm_firewall_policy_rule_collection_group" "azfw_netrule_collection" {
#   name               = "DefaultNetworkRuleCollectionGroup"
#   firewall_policy_id = azurerm_firewall_policy.azfw_hub_policy.id
#   priority           = 200
#   network_rule_collection {
#     name     = "DefaultNetworkRuleCollection"
#     action   = "Allow"
#     priority = 200
#     rule {
#       name                  = "allow-east-west-traffic"
#       protocols             = ["Any"]
#       source_addresses      = [element(local.spoke001_address_space, 0), element(local.spoke002_address_space, 0)]
#       destination_ports     = ["*"]
#       destination_addresses = [element(local.spoke001_address_space, 0), element(local.spoke002_address_space, 0)]
#     }
#   }
# }

# # Create Azure Firewall in Hub
# resource "azurerm_firewall" "azfw_hub" {
#   name                = "azfw-hub"
#   location            = azurerm_resource_group.rg_hub.location
#   resource_group_name = azurerm_resource_group.rg_hub.name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"
#   ip_configuration {
#     name                 = "azfw-ipconfig1"
#     subnet_id            = azurerm_subnet.hub_subnets["AzureFirewallSubnet"].id
#     public_ip_address_id = azurerm_public_ip.azfw_hub_pip.id
#   }
#   firewall_policy_id = azurerm_firewall_policy.azfw_hub_policy.id
# }

# /*
#  Create Jumpbox Virtual Machine in Hub
# */

# # Create Network Interface for Spoke-001 Virtual Machine
# resource "azurerm_network_interface" "vm_jumpbox_nic" {
#   name                = "vm-jumpbox-nic"
#   location            = azurerm_resource_group.rg_hub.location
#   resource_group_name = azurerm_resource_group.rg_hub.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.hub_subnets[var.hub_subnets[1].name].id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # Create Virtual Machine 
# resource "azurerm_linux_virtual_machine" "vm_jumpbox" {
#   name                            = "vm-jumpbox"
#   computer_name                   = "vm-jumpbox"
#   resource_group_name             = azurerm_resource_group.rg_hub.name
#   location                        = azurerm_resource_group.rg_hub.location
#   size                            = "Standard_B1s"
#   disable_password_authentication = false
#   admin_username                  = "adminuser"
#   admin_password                  = var.admin_password
#   network_interface_ids           = [azurerm_network_interface.vm_jumpbox_nic.id]
#   os_disk {
#     name                 = "vm-jumpbox-osdisk"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
# }

# # Create Azure Firewall Policy Rule Collection Group (DNAT Rule)
# resource "azurerm_firewall_policy_rule_collection_group" "azfw_natrule_collection" {
#   name               = "DefaultDnatRuleCollectionGroup"
#   firewall_policy_id = azurerm_firewall_policy.azfw_hub_policy.id
#   priority           = 200
#   nat_rule_collection {
#     name     = "DefaultDnatRuleCollection"
#     priority = 200
#     action   = "Dnat"
#     rule {
#       name                = "nat-jumpbox"
#       source_addresses    = ["*"]
#       destination_address = azurerm_public_ip.azfw_hub_pip.ip_address
#       destination_ports   = ["22"]
#       translated_address  = azurerm_network_interface.vm_jumpbox_nic.ip_configuration[0].private_ip_address
#       translated_port     = "22"
#       protocols           = ["TCP"]
#     }
#   }
# }

/*
Spoke Resources
一旦べた書きで作成する
*/

/*
Spoke-001 Resources
*/

# # Create Spoke-001 Virtual Network
# resource "azurerm_virtual_network" "spoke_vnet_001" {
#   name                = "vnet-spoke-001"
#   resource_group_name = azurerm_resource_group.rg_spoke.name
#   location            = azurerm_resource_group.rg_spoke.location
#   address_space       = local.spoke001_address_space
# }

# # Create Spoke-001 Subnet
# resource "azurerm_subnet" "spoke_001_subnets" {
#   count                = local.spoke_subnet_count
#   name                 = "subnet-${count.index + 1}"
#   resource_group_name  = azurerm_resource_group.rg_spoke.name
#   virtual_network_name = azurerm_virtual_network.spoke_vnet_001.name
#   address_prefixes     = [cidrsubnet(element(azurerm_virtual_network.spoke_vnet_001.address_space, 0), 8, count.index)]
# }

# # Create Spoke-001 Virtual Network Peering
# resource "azurerm_virtual_network_peering" "spoke001_to_hub" {
#   name                      = "spoke001-to-hub"
#   resource_group_name       = azurerm_resource_group.rg_spoke.name
#   virtual_network_name      = azurerm_virtual_network.spoke_vnet_001.name
#   remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true
#   allow_gateway_transit        = false
#   use_remote_gateways          = false
# }

# resource "azurerm_virtual_network_peering" "hub_to_spoke001" {
#   name                      = "hub-to-spoke001"
#   resource_group_name       = azurerm_resource_group.rg_hub.name
#   virtual_network_name      = azurerm_virtual_network.hub_vnet.name
#   remote_virtual_network_id = azurerm_virtual_network.spoke_vnet_001.id

#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true
#   allow_gateway_transit        = false
#   use_remote_gateways          = false
# }

# # Create Network Security Group
# resource "azurerm_network_security_group" "nsg_spoke001" {
#   name                = "nsg-spoke-001"
#   location            = azurerm_resource_group.rg_spoke.location
#   resource_group_name = azurerm_resource_group.rg_spoke.name
#   security_rule {
#     name                       = "SSH"
#     priority                   = 1000
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# # Associate Network Security Group to Spoke-001 Subnets
# resource "azurerm_subnet_network_security_group_association" "nsg_spoke001_association" {
#   count                     = local.spoke_subnet_count
#   network_security_group_id = azurerm_network_security_group.nsg_spoke001.id
#   subnet_id                 = azurerm_subnet.spoke_001_subnets[count.index].id
# }

# # Create Public IP for Spoke-001 Virtual Machine
# resource "azurerm_public_ip" "vm_spoke001_pip" {
#   name                = "vm-spoke001-pip"
#   location            = azurerm_resource_group.rg_spoke.location
#   resource_group_name = azurerm_resource_group.rg_spoke.name
#   sku                 = "Standard"
#   allocation_method   = "Static"
# }

# # Create Network Interface for Spoke-001 Virtual Machine
# resource "azurerm_network_interface" "vm_spoke001_nic" {
#   name                = "vm-spoke001-nic"
#   location            = azurerm_resource_group.rg_spoke.location
#   resource_group_name = azurerm_resource_group.rg_spoke.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.spoke_001_subnets[0].id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm_spoke001_pip.id
#   }
# }

# # Create Virtual Machine in Spoke-001 Subnet
# resource "azurerm_linux_virtual_machine" "vm_spoke001" {
#   name                            = "vm-spoke001"
#   computer_name                   = "vm-spoke001"
#   resource_group_name             = azurerm_resource_group.rg_spoke.name
#   location                        = azurerm_resource_group.rg_spoke.location
#   size                            = "Standard_B1s"
#   disable_password_authentication = false
#   admin_username                  = "adminuser"
#   admin_password                  = var.admin_password
#   network_interface_ids           = [azurerm_network_interface.vm_spoke001_nic.id]
#   os_disk {
#     name                 = "osdisk-spoke001"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
# }

# # Create Route Table
# resource "azurerm_route_table" "spoke001_rt" {
#   name                          = "rt-spoke001"
#   location                      = azurerm_resource_group.rg_spoke.location
#   resource_group_name           = azurerm_resource_group.rg_spoke.name
#   disable_bgp_route_propagation = false
#   route {
#     name                   = "defaultRoute"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = azurerm_firewall.azfw_hub.ip_configuration[0].private_ip_address
#   }
# }

# # Associate Route Table to Spoke-001 Subnets
# resource "azurerm_subnet_route_table_association" "spoken001_rt_association" {
#   count          = local.spoke_subnet_count
#   subnet_id      = azurerm_subnet.spoke_001_subnets[count.index].id
#   route_table_id = azurerm_route_table.spoke001_rt.id
# }

# /*
# Spoke-002 Resources
# */

# # Create Spoke-002 Virtual Network
# resource "azurerm_virtual_network" "spoke_vnet_002" {
#   name                = "vnet-spoke-002"
#   resource_group_name = azurerm_resource_group.rg_spoke.name
#   location            = azurerm_resource_group.rg_spoke.location
#   address_space       = local.spoke002_address_space
# }

# # Create Spoke-002 Subnet
# resource "azurerm_subnet" "spoke_002_subnets" {
#   count                = 2
#   name                 = "subnet-${count.index + 1}"
#   resource_group_name  = azurerm_resource_group.rg_spoke.name
#   virtual_network_name = azurerm_virtual_network.spoke_vnet_002.name
#   address_prefixes     = [cidrsubnet(element(azurerm_virtual_network.spoke_vnet_002.address_space, 0), 8, count.index)]
# }

# # Create Spoke-002 Virtual Network Peering
# resource "azurerm_virtual_network_peering" "spoke002_to_hub" {
#   name                      = "spoke002-to-hub"
#   resource_group_name       = azurerm_resource_group.rg_spoke.name
#   virtual_network_name      = azurerm_virtual_network.spoke_vnet_002.name
#   remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true
#   allow_gateway_transit        = false
#   use_remote_gateways          = false
# }

# resource "azurerm_virtual_network_peering" "hub_to_spoke002" {
#   name                      = "hub-to-spoke002"
#   resource_group_name       = azurerm_resource_group.rg_hub.name
#   virtual_network_name      = azurerm_virtual_network.hub_vnet.name
#   remote_virtual_network_id = azurerm_virtual_network.spoke_vnet_002.id

#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true
#   allow_gateway_transit        = false
#   use_remote_gateways          = false
# }

# # Create Network Security Group
# resource "azurerm_network_security_group" "nsg_spoke002" {
#   name                = "nsg-spoke-002"
#   location            = azurerm_resource_group.rg_spoke.location
#   resource_group_name = azurerm_resource_group.rg_spoke.name
#   security_rule {
#     name                       = "SSH"
#     priority                   = 1000
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# # Associate Network Security Group to Spoke-001 Subnets
# resource "azurerm_subnet_network_security_group_association" "nsg_spoke002_association" {
#   count                     = local.spoke_subnet_count
#   network_security_group_id = azurerm_network_security_group.nsg_spoke002.id
#   subnet_id                 = azurerm_subnet.spoke_002_subnets[count.index].id
# }

# # Create Public IP for Spoke-001 Virtual Machine
# resource "azurerm_public_ip" "vm_spoke002_pip" {
#   name                = "vm-spoke002-pip"
#   location            = azurerm_resource_group.rg_spoke.location
#   resource_group_name = azurerm_resource_group.rg_spoke.name
#   sku                 = "Standard"
#   allocation_method   = "Static"
# }

# # Create Network Interface for Spoke-001 Virtual Machine
# resource "azurerm_network_interface" "vm_spoke002_nic" {
#   name                = "vm-spoke002-nic"
#   location            = azurerm_resource_group.rg_spoke.location
#   resource_group_name = azurerm_resource_group.rg_spoke.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.spoke_002_subnets[0].id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm_spoke002_pip.id
#   }
# }

# # Create Virtual Machine in Spoke-001 Subnet
# resource "azurerm_linux_virtual_machine" "vm_spoke002" {
#   name                            = "vm-spoke002"
#   computer_name                   = "vm-spoke002"
#   resource_group_name             = azurerm_resource_group.rg_spoke.name
#   location                        = azurerm_resource_group.rg_spoke.location
#   size                            = "Standard_B1s"
#   disable_password_authentication = false
#   admin_username                  = "adminuser"
#   admin_password                  = var.admin_password
#   network_interface_ids           = [azurerm_network_interface.vm_spoke002_nic.id]
#   os_disk {
#     name                 = "osdisk-spoke002"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
# }

# # Create Route Table
# resource "azurerm_route_table" "spoke002_rt" {
#   name                          = "rt-spoke002"
#   location                      = azurerm_resource_group.rg_spoke.location
#   resource_group_name           = azurerm_resource_group.rg_spoke.name
#   disable_bgp_route_propagation = false
#   route {
#     name                   = "defaultRoute"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = azurerm_firewall.azfw_hub.ip_configuration[0].private_ip_address
#   }
# }

# # Associate Route Table to Spoke-001 Subnets
# resource "azurerm_subnet_route_table_association" "spoken002_rt_association" {
#   count          = local.spoke_subnet_count
#   subnet_id      = azurerm_subnet.spoke_002_subnets[count.index].id
#   route_table_id = azurerm_route_table.spoke002_rt.id
# }



/*
References:
- https://zenn.dev/kasa/articles/8fe998e04cb916

*/
