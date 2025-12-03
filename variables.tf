variable "subscription_id" {
  type = string
}

variable "region" {
  type = string
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

variable "ipam_api_id" {
  type = string
}

variable "ipam_engine_url" {
  type = string
}

variable "billing_account_name" {
  type = string
}

variable "dev_test_enrollment_account_name" {
  type = string
}

variable "production_enrollment_account_name" {
  type = string
}
