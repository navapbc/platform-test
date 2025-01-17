locals {
  domain_name    = local.service_config.domain_name
  hosted_zone_id = local.domain_name != null ? data.aws_route53_zone.zone[0].zone_id : null
}

data "aws_acm_certificate" "certificate" {
  count  = var.enable_https ? 1 : 0
  domain = var.domain_name
}

data "aws_route53_zone" "zone" {
  name = var.hosted_zone
}
