# このファイルに述されている内容をもとに `terraform init` 時に必要なproviderがインストールされる

terraform {
  # 開発に利用するTerraformとproviderのバージョンを制限する
  # 「Terraformに1.0 以上のバージョンを利用する」という意味
  required_version = "~>1.0"
  
  # 今から書かれるコードで利用するprovider(依存関係)を指定する
  required_providers {
    # Hashicorp社が提供するAzure用のproviderがazurerm
    # azapi_resourceっていうのもあるようで、これはAzure APIを直接叩くprovider
    # Terraformらしくある程度抽象化して使うにはazurermを利用する
    # 一方で、プレビューとかGA前の機能を使いたい場合はazapi_resourceを利用する(バージョン指定ができる)
    azurerm = {
        source = "hashicorp/azurerm"
        # azurermの3.0以上のバージョンを利用する
        version = "~>3.0"
    } 
    # Hashicorp社が提供するランダムな文字列を生成するproviderがrandom
    # BicepだとuniqueString()関数を利用できるが、Terraformでは宣言的に書く必要がある
    random = {
        source = "hashicorp/random"
        # randomの3.0以上のバージョンを利用する
        version = "~>3.0"
    }
  }
}

# providerの既定の動作を変更する場合は、ここに記述する
# reference: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
provider "azurerm" {
  features {}
}