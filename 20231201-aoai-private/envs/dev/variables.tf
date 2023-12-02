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

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "client_ip" {
  type = string
}