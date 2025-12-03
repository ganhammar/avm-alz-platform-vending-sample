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

variable "management_group_id" {
  type = string
}
