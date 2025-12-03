# Enrollment Accounts
data "azurerm_billing_enrollment_account_scope" "dev_test" {
  billing_account_name    = var.billing_account_name
  enrollment_account_name = var.dev_test_enrollment_account_name
}

data "azurerm_billing_enrollment_account_scope" "production" {
  billing_account_name    = var.billing_account_name
  enrollment_account_name = var.production_enrollment_account_name
}

# Subscriptions
locals {
  sandbox_subscriptions_raw            = file("${path.module}/../../subscriptions/sandboxes.yml")
  landingzone_corp_subscriptions_raw   = file("${path.module}/../../subscriptions/landingzones/corp.yml")
  landingzone_online_subscriptions_raw = file("${path.module}/../../subscriptions/landingzones/online.yml")

  sandbox_subscriptions            = try(coalesce(yamldecode(local.sandbox_subscriptions_raw), []), [])
  landingzone_corp_subscriptions   = try(coalesce(yamldecode(local.landingzone_corp_subscriptions_raw), []), [])
  landingzone_online_subscriptions = try(coalesce(yamldecode(local.landingzone_online_subscriptions_raw), []), [])
}

# Sandbox
module "sandbox" {
  source = "./subscription"

  for_each = {
    for subscription in local.sandbox_subscriptions :
    "${subscription.name}-sandbox" => subscription
  }

  name                    = each.value.name
  cost_center             = each.value.costCenter
  region                  = each.value.region
  budgets                 = try(each.value.budgets, [])
  owners                  = each.value.owners
  billing_scope           = data.azurerm_billing_enrollment_account_scope.dev_test.id
  workload_type           = "DevTest"
  management_group_id     = var.alz_management_groups["sandbox"]
  hub_network_resource_id = var.hub_network_resource_id
  ipam_space              = var.ipam_europe_space
  ipam_block              = var.ipam_europe_block
}

# Landing Zone - Corp
module "landingzone_corp" {
  source = "./subscription"
  for_each = {
    for subscription in local.landingzone_corp_subscriptions :
    "${subscription.name}-corp" => subscription
  }

  name        = each.value.name
  cost_center = each.value.costCenter
  region      = each.value.region
  budgets     = try(each.value.budgets, [])
  owners      = each.value.owners
  billing_scope = each.value.workloadType == "Production" ? (
    data.azurerm_billing_enrollment_account_scope.production.id
    ) : (
    data.azurerm_billing_enrollment_account_scope.dev_test.id
  )
  workload_type           = each.value.workloadType
  management_group_id     = var.alz_management_groups["corp"]
  hub_network_resource_id = var.hub_network_resource_id
  ipam_space              = var.ipam_europe_space
  ipam_block              = var.ipam_europe_block
}

# Landing Zone - Online
module "landingzone_online" {
  source = "./subscription"
  for_each = {
    for subscription in local.landingzone_online_subscriptions :
    "${subscription.name}-online" => subscription
  }
  name        = each.value.name
  cost_center = each.value.costCenter
  region      = each.value.region
  budgets     = try(each.value.budgets, [])
  owners      = each.value.owners
  billing_scope = each.value.workloadType == "Production" ? (
    data.azurerm_billing_enrollment_account_scope.production.id
    ) : (
    data.azurerm_billing_enrollment_account_scope.dev_test.id
  )
  workload_type           = each.value.workloadType
  management_group_id     = var.alz_management_groups["online"]
  hub_network_resource_id = var.hub_network_resource_id
  ipam_space              = var.ipam_europe_space
  ipam_block              = var.ipam_europe_block
}
