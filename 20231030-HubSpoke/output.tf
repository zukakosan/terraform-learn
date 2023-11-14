output "azfw_public_ip" {
  value = azurerm_public_ip.azfw_hub_pip.ip_address
}