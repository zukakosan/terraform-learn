variable "rg_location" {
  default = "japaneast"
  description = "Azure Region for all resources in this deployment"
}

variable "rg_prefix" {
  default = "tf-deploy"
  description = "Prefix for all resources in this deployment"
}

variable "spoke_vnets_address_spaces" {
  default = [
    {
      name = "vnet-spoke1"
      address_space = "10.10.0.0/16"
    },
    {
      name = "vnet-spoke2"
      address_space = "10.20.0.0/16"
    }
  ]
  description = "values for the address spaces of the spoke vnets"
}

variable "hub_subnets" {
  default = [
      {
        name = "AzureFirewallSubnet"
        address_prefixes = "10.0.0.0/24"
      },
      {
        name = "subnet-hub-001"
        address_prefixes = "10.0.100.0/24"
      }
    ]
}

variable "admin_password" {
  default = "P@ssw0rd1234"
  description = "admin password"
}