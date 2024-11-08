locals {
  dash_domain = replace(var.domain_name, ".", "-")
}

data "aws_sesv2_email_identity" "main" {
  email_identity = var.domain_name
}

data "aws_sesv2_configuration_set" "main" {
  configuration_set_name = local.dash_domain
}
