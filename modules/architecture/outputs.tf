output "alz_management_groups" {
  description = "Map of all management group names to their resource IDs"
  value       = module.azure_landing_zone.management_group_resource_ids
}

output "hub_network_resource_id" {
  description = "Resource ID of the hub network"
  value       = module.hub_and_spoke_network.virtual_network_resource_ids["primary"]
}
