variable "rg_name" {
  type = string
  description = "name of resource group"
}

variable "location" {
  type    = string
  default = "japaneast"
}

variable "env" {
  type = string
  description = "environment name"
}

variable "vnet_name" {
  type = string
  description = "virtual network name"
}

variable "address_space" {
  type = string
  description = "address space of virtual network"
}

variable "jumpbox_subnet_address_space" {
  type = string
  description = "address space of jumpbox subnet in virtual network"
}

variable "pe_subnet_address_space" {
  type = string
  description = "address space of private endpoint subnet in virtual network"
}

variable "admin_username" {
  type = string
  description = "admin username of jumpbox"
}

variable "admin_password" {
  type      = string
  sensitive = true
  description = "admin password of jumpbox"
}

variable "client_ip" {
  type = string
  description = "ip address of client to access jumpbox"
}