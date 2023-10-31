/*
local values
*/
locals {
#   hub_address_space      = ["10.0.0.0/16"]
  spoke001_address_space = ["10.10.0.0/16"]
  spoke002_address_space = ["10.20.0.0/16"]
#   spoke_subnet_count     = 2
}

# Create Spoke-001 Virtual Network
resource "azurerm_virtual_network" "spoke_vnet_001" {
  name                = "vnet-spoke-001"
  resource_group_name = azurerm_resource_group.rg_spoke.name
  location            = azurerm_resource_group.rg_spoke.location
  address_space       = local.spoke001_address_space
}

# Create Spoke-001 Subnet
resource "azurerm_subnet" "spoke_001_subnets" {
  count                = local.spoke_subnet_count
  name                 = "subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg_spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet_001.name
  address_prefixes     = [cidrsubnet(element(azurerm_virtual_network.spoke_vnet_001.address_space, 0), 8, count.index)]
}

# Create Spoke-001 Virtual Network Peering
resource "azurerm_virtual_network_peering" "spoke001_to_hub" {
  name                      = "spoke001-to-hub"
  resource_group_name       = azurerm_resource_group.rg_spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet_001.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke001" {
  name                      = "hub-to-spoke001"
  resource_group_name       = azurerm_resource_group.rg_hub.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet_001.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg_spoke001" {
  name                = "nsg-spoke-001"
  location            = azurerm_resource_group.rg_spoke.location
  resource_group_name = azurerm_resource_group.rg_spoke.name
  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate Network Security Group to Spoke-001 Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_spoke001_association" {
  count                     = local.spoke_subnet_count
  network_security_group_id = azurerm_network_security_group.nsg_spoke001.id
  subnet_id                 = azurerm_subnet.spoke_001_subnets[count.index].id
}

# Create Public IP for Spoke-001 Virtual Machine
resource "azurerm_public_ip" "vm_spoke001_pip" {
  name                = "vm-spoke001-pip"
  location            = azurerm_resource_group.rg_spoke.location
  resource_group_name = azurerm_resource_group.rg_spoke.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

# Create Network Interface for Spoke-001 Virtual Machine
resource "azurerm_network_interface" "vm_spoke001_nic" {
  name                = "vm-spoke001-nic"
  location            = azurerm_resource_group.rg_spoke.location
  resource_group_name = azurerm_resource_group.rg_spoke.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke_001_subnets[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_spoke001_pip.id
  }
}

# Create Virtual Machine in Spoke-001 Subnet
resource "azurerm_linux_virtual_machine" "vm_spoke001" {
  name                            = "vm-spoke001"
  computer_name                   = "vm-spoke001"
  resource_group_name             = azurerm_resource_group.rg_spoke.name
  location                        = azurerm_resource_group.rg_spoke.location
  size                            = "Standard_B1s"
  disable_password_authentication = false
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  network_interface_ids           = [azurerm_network_interface.vm_spoke001_nic.id]
  os_disk {
    name                 = "osdisk-spoke001"
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

# Create Route Table
resource "azurerm_route_table" "spoke001_rt" {
  name                          = "rt-spoke001"
  location                      = azurerm_resource_group.rg_spoke.location
  resource_group_name           = azurerm_resource_group.rg_spoke.name
  disable_bgp_route_propagation = false
  route {
    name                   = "defaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfw_hub.ip_configuration[0].private_ip_address
  }
}

# Associate Route Table to Spoke-001 Subnets
resource "azurerm_subnet_route_table_association" "spoken001_rt_association" {
  count          = local.spoke_subnet_count
  subnet_id      = azurerm_subnet.spoke_001_subnets[count.index].id
  route_table_id = azurerm_route_table.spoke001_rt.id
}

/*
Spoke-002 Resources
*/

# Create Spoke-002 Virtual Network
resource "azurerm_virtual_network" "spoke_vnet_002" {
  name                = "vnet-spoke-002"
  resource_group_name = azurerm_resource_group.rg_spoke.name
  location            = azurerm_resource_group.rg_spoke.location
  address_space       = local.spoke002_address_space
}

# Create Spoke-002 Subnet
resource "azurerm_subnet" "spoke_002_subnets" {
  count                = 2
  name                 = "subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg_spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet_002.name
  address_prefixes     = [cidrsubnet(element(azurerm_virtual_network.spoke_vnet_002.address_space, 0), 8, count.index)]
}

# Create Spoke-002 Virtual Network Peering
resource "azurerm_virtual_network_peering" "spoke002_to_hub" {
  name                      = "spoke002-to-hub"
  resource_group_name       = azurerm_resource_group.rg_spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet_002.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke002" {
  name                      = "hub-to-spoke002"
  resource_group_name       = azurerm_resource_group.rg_hub.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet_002.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg_spoke002" {
  name                = "nsg-spoke-002"
  location            = azurerm_resource_group.rg_spoke.location
  resource_group_name = azurerm_resource_group.rg_spoke.name
  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate Network Security Group to Spoke-001 Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_spoke002_association" {
  count                     = local.spoke_subnet_count
  network_security_group_id = azurerm_network_security_group.nsg_spoke002.id
  subnet_id                 = azurerm_subnet.spoke_002_subnets[count.index].id
}

# Create Public IP for Spoke-001 Virtual Machine
resource "azurerm_public_ip" "vm_spoke002_pip" {
  name                = "vm-spoke002-pip"
  location            = azurerm_resource_group.rg_spoke.location
  resource_group_name = azurerm_resource_group.rg_spoke.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

# Create Network Interface for Spoke-001 Virtual Machine
resource "azurerm_network_interface" "vm_spoke002_nic" {
  name                = "vm-spoke002-nic"
  location            = azurerm_resource_group.rg_spoke.location
  resource_group_name = azurerm_resource_group.rg_spoke.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke_002_subnets[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_spoke002_pip.id
  }
}

# Create Virtual Machine in Spoke-001 Subnet
resource "azurerm_linux_virtual_machine" "vm_spoke002" {
  name                            = "vm-spoke002"
  computer_name                   = "vm-spoke002"
  resource_group_name             = azurerm_resource_group.rg_spoke.name
  location                        = azurerm_resource_group.rg_spoke.location
  size                            = "Standard_B1s"
  disable_password_authentication = false
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  network_interface_ids           = [azurerm_network_interface.vm_spoke002_nic.id]
  os_disk {
    name                 = "osdisk-spoke002"
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

# Create Route Table
resource "azurerm_route_table" "spoke002_rt" {
  name                          = "rt-spoke002"
  location                      = azurerm_resource_group.rg_spoke.location
  resource_group_name           = azurerm_resource_group.rg_spoke.name
  disable_bgp_route_propagation = false
  route {
    name                   = "defaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfw_hub.ip_configuration[0].private_ip_address
  }
}

# Associate Route Table to Spoke-001 Subnets
resource "azurerm_subnet_route_table_association" "spoken002_rt_association" {
  count          = local.spoke_subnet_count
  subnet_id      = azurerm_subnet.spoke_002_subnets[count.index].id
  route_table_id = azurerm_route_table.spoke002_rt.id
}