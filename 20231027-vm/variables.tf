# オブジェクトのような形で各変数を書いていく
variable "resource_group_location" {
  default = "eastus"
  description = "location of rg"
}

variable "admin_password" {
  default = "P@ssw0rd1234"
  description = "admin password"
}