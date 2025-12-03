module "architecture" {
  source                             = "./modules/architecture"
  region                             = var.region
  enable_telemetry                   = var.enable_telemetry
}

module "ipam" {
  source = "./modules/ipam"
}

module "subscriptions" {
  source                             = "./modules/subscriptions"
  billing_account_name               = var.billing_account_name
  dev_test_enrollment_account_name   = var.dev_test_enrollment_account_name
  production_enrollment_account_name = var.production_enrollment_account_name
  ipam_europe_space                  = module.ipam.europe_space
  ipam_europe_block                  = module.ipam.europe_block
  alz_management_groups              = module.architecture.alz_management_groups
  hub_network_resource_id            = module.architecture.hub_network_resource_id
}
