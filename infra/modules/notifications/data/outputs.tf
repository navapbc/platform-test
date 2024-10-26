output "email_configuration_set_name" {
  value = data.aws_sesv2_configuration_set.main.configuration_set_name
}

output "email_identity_arn" {
  value = data.aws_sesv2_email_identity.main.arn
}
