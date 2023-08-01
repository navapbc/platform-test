locals {
  app_name                        = "app"
  environments                    = ["dev", "staging", "prod"]
  project_name                    = module.project_config.project_name
  image_repository_name           = "${local.project_name}-${local.app_name}"
  image_repository_account_name   = "dev"
  has_database                    = true
  has_incident_management_service = false
  environment_configs = {
    dev     = module.dev_config
    staging = module.staging_config
    prod    = module.prod_config
  }
}

module "project_config" {
  source = "../../project-config"
}

module "dev_config" {
  source                          = "./env-config"
  app_name                        = local.app_name
  environment                     = "dev"
  account_name                    = "dev"
  has_database                    = local.has_database
  has_incident_management_service = local.has_incident_management_service
}

module "staging_config" {
  source                          = "./env-config"
  app_name                        = local.app_name
  environment                     = "staging"
  account_name                    = "staging"
  has_database                    = local.has_database
  has_incident_management_service = local.has_incident_management_service
}

module "prod_config" {
  source                          = "./env-config"
  app_name                        = local.app_name
  environment                     = "prod"
  account_name                    = "prod"
  has_database                    = local.has_database
  has_incident_management_service = local.has_incident_management_service
}
