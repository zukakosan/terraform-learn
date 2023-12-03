variable "resource_group_name" {}
variable "location" {}
variable "suffix" {}
variable "vnet_id" {}
variable "subnet_id" {}
variable "random_id" {}

# Create Azure Open AI Service
resource "azurerm_cognitive_account" "aoai" {
  name                = "aoai-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
  custom_subdomain_name = "aoai-${var.random_id}-${var.suffix}"
  public_network_access_enabled = false
}

# Create chat model
resource "azurerm_cognitive_deployment" "chat" {
  name                 = "aoai-${var.suffix}-chat-model"
  cognitive_account_id = azurerm_cognitive_account.aoai.id
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0613"
  }
  scale {
    type = "Standard"
  }
}

# Create Private DNS Zone for Azure Open AI Service
resource "azurerm_private_dns_zone" "aoai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
}

# Create Private Endpoint for Azure Open AI Service
resource "azurerm_private_endpoint" "aoai" {
  name                = "aoai-${var.suffix}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "aoai-${var.suffix}-psc"
    is_manual_connection           = false
    subresource_names              = ["account"]
    private_connection_resource_id = azurerm_cognitive_account.aoai.id
  }

  private_dns_zone_group {
    name                 = "aoai-${var.suffix}-pdzg"
    private_dns_zone_ids = [azurerm_private_dns_zone.aoai.id]
  }
}

# Associate Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "aoai" {
  name                  = "aoai-${var.suffix}-pdnz-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aoai.name
  virtual_network_id    = var.vnet_id
}
