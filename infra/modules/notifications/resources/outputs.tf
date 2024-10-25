output "email_configuration_set_name" {
  value = aws_sesv2_configuration_set.email.configuration_set_name
}

output "email_identity_arn" {
  value = aws_sesv2_email_identity.sender.arn
}

output "verified_email_identity_arn" {
  value = aws_sesv2_email_identity.sender.verified_for_sending_status ? aws_sesv2_email_identity.sender.arn : null
}
