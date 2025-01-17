locals {
  domain_config = local.network_config.domain_config
  hosted_zone   = local.domain_config.hosted_zone
  domain_name   = local.service_config.domain_name
  enable_https  = local.service_config.enable_https
}

module "domain" {
  source       = "../../modules/domain/data"
  hosted_zone  = local.hosted_zone
  domain_name  = local.domain_name
  enable_https = local.enable_https
}
