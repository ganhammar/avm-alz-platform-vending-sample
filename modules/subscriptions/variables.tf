variable "billing_account_name" {
  type = string
}

variable "dev_test_enrollment_account_name" {
  type = string
}

variable "production_enrollment_account_name" {
  type = string
}

variable "alz_management_groups" {
  type = map(string)
}
