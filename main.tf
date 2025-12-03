module "architecture" {
  source                             = "./modules/architecture"
  region                             = var.region
  enable_telemetry                   = var.enable_telemetry
}

module "subscriptions" {
  source                             = "./modules/subscriptions"
  billing_account_name               = var.billing_account_name
  dev_test_enrollment_account_name   = var.dev_test_enrollment_account_name
  production_enrollment_account_name = var.production_enrollment_account_name
  alz_management_groups              = module.architecture.alz_management_groups
}
