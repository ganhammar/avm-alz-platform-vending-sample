output "europe_space" {
  description = "The IPAM space name"
  value       = azureipam_space.europe.name
}

output "europe_block" {
  description = "The IPAM block name"
  value       = azureipam_block.europe.name
}
