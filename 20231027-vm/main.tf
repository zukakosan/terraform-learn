# 今のAzureのコンテキストに対して以下の構成によってデプロイする形になる
# 例えばリソースグループ名を変更しても増分デプロイにはならない
# コンテキストを別のサブスクリプションに設定し、`terraform apply`することで同じ環境が複製できる

# リソースの定義を書いていく

# 1つ目の""で囲まれた部分は、providerの名前、2つ目の""で囲まれた部分は、シンボリック名を入れる
# リソースグループの作成
resource "azurerm_resource_group" "rg_main" {
  location = var.resource_group_location
#   terraformのrandomプロバイダーのrandom_petを利用して、ランダムな文字列を生成する
  name = "rg-tfvm-${random_pet.suffix.id}"
  # 日付で動的に名前を付けると、デプロイ時に別リソース扱いになってしまい、元のリソースグループが消え、新規のリソースグループが生成されてしまうのでやめた
  # name = "${formatdate("YYYYMMDD", timestamp())}-${random_pet.suffix.id}"
}

# 仮想ネットワークの作成
resource "azurerm_virtual_network" "vnet_main" {
# {provider名}.{シンボリック名}.{プロパティ}という形で値を取り出す
  resource_group_name = azurerm_resource_group.rg_main.name
#   リソースグループと同じ場所にする
  location = azurerm_resource_group.rg_main.location
#   ランダム文字列とconcatして文字列生成
  name = "vnet-${random_pet.suffix.id}" 
  address_space = [ "10.0.0.0/16" ]
}

# サブネットの作成
# TerraformにはBicepでいうParent/Childの概念はないっぽい
resource "azurerm_subnet" "vnet_main_subnet" {
  name = "subnet-${azurerm_virtual_network.vnet_main.name}"
  resource_group_name = azurerm_resource_group.rg_main.name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes = [ "10.0.1.0/24" ]
}

# Public IPの作成
resource "azurerm_public_ip" "public_ip_vmnic" {
  name = "public-ip-${random_pet.suffix.id}"
  location = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  allocation_method = "Static"
}

# NSGの作成
resource "azurerm_network_security_group" "nsg_deafault" {
  name                = "nsg-${random_pet.suffix.id}"
  location            = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
# 接続用の規則を記述
  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NICの作成
resource "azurerm_network_interface" "nic" {
  name = "nic-${random_pet.suffix.id}"
  location = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name

  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.vnet_main_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip_vmnic.id
  }
}

# NSGとSubnetの紐づけ
# これが宣言できるのはかなり便利かも
# Bicepでは後付けでNSGをアタッチすると構文が冗長になる
resource "azurerm_subnet_network_security_group_association" "nsg_subnet_main" {
  network_security_group_id = azurerm_network_security_group.nsg_deafault.id
  subnet_id = azurerm_subnet.vnet_main_subnet.id
}

# 仮想マシンの作成
resource "azurerm_windows_virtual_machine" "vm-win" {
  name = "vm-win-001"
  location = azurerm_resource_group.rg_main.location
  resource_group_name = azurerm_resource_group.rg_main.name
  admin_username = "AzureAdmin"
  admin_password = var.admin_password
  network_interface_ids = [ azurerm_network_interface.nic.id ]
  size = "Standard_B2ms"

  os_disk {
    name = "osdisk-${random_pet.suffix.id}"
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2022-Datacenter"
    version = "latest"
  }
}

# カスタムスクリプト拡張機能で仮想マシンにIISを入れる
# これもBicepだと子リソースの扱いだけど、そうでもないらしい
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name = "wsi-${random_pet.suffix.id}"
  virtual_machine_id = azurerm_windows_virtual_machine.vm-win.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}

# random_petのインスタンス？実体を定義する
# randam_pet自体はlengthに合わせてペット名を作るっていうちょっと変わった関数
resource "random_pet" "suffix" {
  length = 1
}