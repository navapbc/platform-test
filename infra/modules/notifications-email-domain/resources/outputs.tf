output "domain_identity_arn" {
  value = aws_sesv2_email_identity.sender_domain.arn
}

output "configuration_set_name" {
  value = aws_sesv2_configuration_set.email.configuration_set_name
}

output "email_identity" {
  value = aws_sesv2_email_identity.sender_domain.email_identity
}
