variable "region" {
  type = string
}

variable "private_dns_zone_resource_group_id" {
  type = string
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
