locals {
  stripped_domain_name = replace(var.domain_name, "/[.]$/", "")
}

data "aws_sesv2_email_identity" "main" {
  email_identity = local.stripped_domain_name
}

data "aws_sesv2_configuration_set" "main" {
  configuration_set_name = var.name
}
