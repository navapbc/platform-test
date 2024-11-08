output "email_identity_config" {
  value = aws_sesv2_configuration_set.email.configuration_set_name
}

output "domain_identity_arn" {
  value = aws_sesv2_email_identity.sender.arn
}
