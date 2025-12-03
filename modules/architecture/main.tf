data "azapi_client_config" "current" {}

# Configure the ALZ Provider With Library References
provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2025.09.3"
    },
    {
      custom_url = "${path.module}/lib"
    }
  ]
}

# Hub and Spoke Network (Hub, Firewall, DNS Resolver)
module "resource_group_hub_network" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.2.0"
  location         = var.region
  name             = "rg-hub-network"
  enable_telemetry = var.enable_telemetry
}

module "hub_and_spoke_network" {
  source           = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version          = "v0.16.2"
  enable_telemetry = var.enable_telemetry
  hub_virtual_networks = {
    primary = {
      location          = var.region
      default_parent_id = module.resource_group_hub_network.resource_id
    }
  }
}

# Private DNS Zones
module "resource_group_private_dns_zones" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.2.0"
  location         = var.region
  name             = "rg-private-dns-zones"
  enable_telemetry = var.enable_telemetry
}

module "private_dns_zones" {
  source           = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version          = "v0.22.2"
  location         = var.region
  parent_id        = module.resource_group_private_dns_zones.resource_id
  enable_telemetry = var.enable_telemetry
  virtual_network_link_default_virtual_networks = {
    for key, vnet in module.hub_and_spoke_network.virtual_network_resource_ids : key => {
      virtual_network_resource_id = vnet
    }
  }
}

# Management Groups, Policies, and Custom Roles
module "azure_landing_zone" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "v0.14.1"

  architecture_name  = "alz"
  location           = var.region
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = var.enable_telemetry
  policy_default_values = {
    private_dns_zone_subscription_id     = jsonencode({ value = data.azapi_client_config.current.subscription_id })
    private_dns_zone_region              = jsonencode({ value = var.region })
    private_dns_zone_resource_group_name = jsonencode({ value = module.resource_group_private_dns_zones.name })
  }
  dependencies = {
    policy_assignments = [
      module.private_dns_zones.private_dns_zone_resource_ids
    ]
  }
}
