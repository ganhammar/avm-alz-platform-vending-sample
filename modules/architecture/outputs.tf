output "alz_management_groups" {
  description = "Map of all management group names to their resource IDs"
  value       = module.azure_landing_zone.management_group_resource_ids
}

output "dns_server_ip_addresses" {
  description = "List of DNS server IP addresses deployed in the hub"
  value       = try(tolist(module.hub_and_spoke_network.dns_server_ip_addresses), [])
}

output "hub_network_resource_id" {
  description = "Resource ID of the hub network"
  value       = module.hub_and_spoke_network.virtual_network_resource_ids["primary"]
}
