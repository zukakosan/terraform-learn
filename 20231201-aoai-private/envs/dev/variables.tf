variable "rg_name" {
  type = string
}

variable "location" {
  type    = string
  default = "japaneast"
}

variable "env" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "address_space" {
  type = string
}

variable "jumpbox_subnet_address_space" {
  type = string
}

variable "pe_subnet_address_space" {
  type = string
}