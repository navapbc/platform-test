locals {
  network_name   = "dev"
  network_config = module.project_config.network_configs[local.network_name]
  domain_name    = "${local.app_name}.${local.network_config.domain_config.hosted_zone}"
}

module "dev_config" {
  source                          = "./env-config"
  project_name                    = local.project_name
  app_name                        = local.app_name
  default_region                  = module.project_config.default_region
  environment                     = "dev"
  network_name                    = local.network_name
  domain_name                     = local.domain_name
  enable_https                    = true
  has_database                    = local.has_database
  has_incident_management_service = local.has_incident_management_service
  enable_notifications            = local.enable_notifications

  # Enable and configure identity provider.
  enable_identity_provider = local.enable_identity_provider

  # Support local development against the dev instance.
  extra_identity_provider_callback_urls = ["http://localhost"]
  extra_identity_provider_logout_urls   = ["http://localhost"]

  # Enables ECS Exec access for debugging or jump access.
  # See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html
  # Defaults to `false`. Uncomment the next line to enable.
  # enable_command_execution = true
}
