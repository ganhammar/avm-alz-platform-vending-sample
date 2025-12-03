variable "billing_account_name" {
  type = string
}

variable "dev_test_enrollment_account_name" {
  type = string
}

variable "production_enrollment_account_name" {
  type = string
}

variable "ipam_europe_space" {
  type = string
}

variable "ipam_europe_block" {
  type = string
}

variable "alz_management_groups" {
  type = map(string)
}

variable "hub_network_resource_id" {
  type = string
}
