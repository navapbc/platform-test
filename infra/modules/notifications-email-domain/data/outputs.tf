output "domain_identity_arn" {
  value = data.aws_sesv2_email_identity.main.arn
}

output "configuration_set_name" {
  value = data.aws_sesv2_email_identity.main.configuration_set_name
}

output "email_identity" {
  value = data.aws_sesv2_email_identity.main.email_identity
}
