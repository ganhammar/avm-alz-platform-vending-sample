locals {
  spaces = flatten([
    for vnet in var.vnets : (
      concat(
        contains(keys(vnet), "spaces") ? [
          for space in vnet.spaces : {
            vnet_name = vnet.name
            purpose   = space.purpose
            size      = space.size
          }
        ] : [],
        [{
          vnet_name = vnet.name
          purpose   = "Private Endpoints"
          size      = 28
        }]
      )
    )
  ])
  group_types  = ["reader", "contributor", "owner"]
  vnet_rg_name = "rg-vnets"
}

data "azapi_client_config" "current" {}

data "azuread_users" "owners_mail" {
  mails          = var.owners
  ignore_missing = true
}

# Entra Groups
resource "azuread_group" "groups" {
  for_each = toset(local.group_types)

  display_name     = "aad-${var.name}-${each.key}"
  mail_enabled     = false
  security_enabled = true

  owners = concat(
    [data.azapi_client_config.current.object_id],
    data.azuread_users.owners_mail.users[*].object_id
  )
}

# Reserve IP space
resource "azureipam_reservation" "reservations" {
  for_each = {
    for vnet in var.vnets : vnet.name => [
      for space in local.spaces : space if space.vnet_name == vnet.name
    ]
  }

  space       = var.ipam_space
  blocks      = [var.ipam_block]
  size        = each.value[0].size
  description = join(", ", [for space in each.value : space.purpose])
}

# Create Subscription Module
module "subscription" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "v0.1.0"

  # Subscription Settings
  location = var.region

  subscription_alias_enabled = true
  subscription_billing_scope = var.billing_scope
  subscription_display_name  = var.name
  subscription_alias_name    = var.name
  subscription_workload      = var.workload_type

  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = var.management_group_id

  # Virtual Networks
  virtual_network_enabled = length(var.vnets) > 0
  virtual_networks = length(var.vnets) > 0 ? {
    for vnet in var.vnets : vnet.name => {
      name                    = vnet.name
      location                = var.region
      hub_peering_enabled     = true
      hub_network_resource_id = var.hub_network_resource_id
      address_space           = [azureipam_reservation.reservations[vnet.name].cidr_block]
      tags = {
        # IPAM will associate VNET with the block and remove reservation
        X-IPAM-RES-ID = join(", ", azureipam_reservation.reservations[vnet.name].id)
      }
    }
  } : null

  # Resource Groups
  resource_group_creation_enabled = true
  resource_groups = {
    nwrg = {
      name     = "NetworkWatcherRG"
      location = "westeurope"
    }
    vnetrg = {
      name     = local.vnet_rg_name
      location = var.region
    }
  }

  # Active Role Assignments
  role_assignment_enabled = true
  role_assignments = {
    contrib_user_sub = {
      principal_id   = azuread_group.groups["reader"].id
      definition     = "Reader"
      relative_scope = ""
    }
  }

  # Budgets
  budget_enabled = length(var.budgets) > 0 ? true : false
  budgets = {
    for budget in var.budgets : "${var.name}-budget-${budget.year}" => {
      name              = "${var.name}-budget-${budget.year}"
      amount            = budget.amount
      time_grain        = "Annually"
      time_period_start = "${budget.year}-01-01T00:00:00Z"
      time_period_end   = "${budget.year}-12-31T23:59:59Z"
      otifications = {
        eightypercent = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 80
          threshold_type = "Actual"
          contact_roles  = ["CorpOwner"]
        }
        budgetexceeded = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 120
          threshold_type = "Forecasted"
          contact_roles  = ["CorpOwner"]
        }
      }
    }
  }

  # Tags
  subscription_tags = {
    CostCenter = var.cost_center
  }
}

locals {
  # Map of roles which the "owner" group should not be able to assign
  delegated_roles = {
    "Contributor"                             = "b24988ac-6180-42a0-ab88-20f7382dd24c"
    "Owner"                                   = "8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
    "Reservations Administrator"              = "a8889054-8d42-49c9-bc1c-52486c10e7cd"
    "Role Based Access Control Administrator" = "f58310d9-a9f6-439a-9e8d-f62e7b41a168"
    "User Access Administrator"               = "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"
    "Network Contributor"                     = "4d97b98b-1d4f-4787-a291-c67834d212e7"
  }
  delegated_role_ids_string = join(", ", values(local.delegated_roles))
  owner_condition           = <<-EOT
  (
    (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
    )
    OR
    (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${local.delegated_role_ids_string}}
    )
  )
  AND
  (
    (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
    )
    OR
    (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${local.delegated_role_ids_string}}
    )
  )
EOT
}

# PIM Eligible Contributor Role Assignment, Allows All Except Network and Authorization Write
resource "azurerm_pim_eligible_role_assignment" "contributor" {
  scope              = "/subscriptions/${module.subscription.subscription_id}"
  role_definition_id = "/subscriptions/${module.subscription.subscription_id}/alz/Application-Owners"
  principal_id       = azuread_group.groups["contributor"].object_id
}

# PIM Eligible Owner Role Assignment, Allows All Except Network Write
resource "azurerm_pim_eligible_role_assignment" "owner" {
  scope              = "/subscriptions/${module.subscription.subscription_id}"
  role_definition_id = "/subscriptions/${module.subscription.subscription_id}/CorpOwner"
  principal_id       = azuread_group.groups["owner"].object_id

  condition_version = "2.0"
  condition         = local.owner_condition
}

# Create Service Principal
resource "azuread_application" "app" {
  display_name = "sp-${var.name}"
  owners = concat(
    [data.azapi_client_config.current.object_id],
    data.azuread_users.owners_mail.users[*].object_id
  )
}

resource "azuread_service_principal" "sp" {
  client_id = azuread_application.app.client_id
}

resource "azurerm_role_assignment" "sp_role_assignments" {
  scope              = "/subscriptions/${module.subscription.subscription_id}"
  role_definition_id = "/subscriptions/${module.subscription.subscription_id}/CorpOwner"
  principal_id       = azuread_service_principal.sp.object_id
  condition_version  = "2.0"
  condition          = local.owner_condition
}
