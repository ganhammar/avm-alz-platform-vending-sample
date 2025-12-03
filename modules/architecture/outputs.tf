output "alz_management_groups" {
  description = "Map of all management group names to their resource IDs"
  value       = module.azure_landing_zone.management_group_resource_ids
}
