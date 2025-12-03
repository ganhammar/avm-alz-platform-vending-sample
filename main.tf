module "architecture" {
  source                             = "./modules/architecture"
  region                             = var.region
  enable_telemetry                   = var.enable_telemetry
}
