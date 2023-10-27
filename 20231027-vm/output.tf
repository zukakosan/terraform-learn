# 出力に載せたい内容をここに書く
output "resouce_group_name" {
  value = azurerm_resource_group.rg_main.name
}

output "vm_public_ip_address" {
  value = azurerm_public_ip.public_ip_vmnic.ip_address
}

output "vm_admin_name" {
  value = azurerm_windows_virtual_machine.vm-win.admin_username
}

output "vm_admin_pasword" {
# Bicepの@Secure()と同じような機能
  sensitive = true
  value = azurerm_windows_virtual_machine.vm-win.admin_password
}