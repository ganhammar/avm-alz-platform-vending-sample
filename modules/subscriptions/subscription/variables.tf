# User Variables
variable "name" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "region" {
  type = string
}

variable "budgets" {
  type = list(object({
    year   = number
    amount = number
  }))
  default = []
}

variable "owners" {
  type    = list(string)
  default = []
}

variable "workload_type" {
  type = string
  validation {
    condition     = contains(["Production", "DevTest"], var.workload_type)
    error_message = "workload_type must be either 'Production' or 'DevTest'."
  }
}

# System Variables
variable "billing_scope" {
  type = string
}

variable "vnets" {
  type = list(object({
    name   = string
    region = string
    spaces = optional(list(object({
      purpose = string
      size    = string
    })))
  }))
  default = []
}

variable "dns_server_ip_addresses" {
  type    = list(string)
  default = []
}

variable "management_group_id" {
  type = string
}

variable "hub_network_resource_id" {
  type = string
}

variable "ipam_space" {
  type = string
}

variable "ipam_block" {
  type = string
}
