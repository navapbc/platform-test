output "dkim_dns_verification_records" {
  value = local.dkim_dns_verification_records
}

output "dkim_status" {
  value = var.email_verification_method == "email" ? "" : aws_sesv2_email_identity.sender.dkim_signing_attributes[0].status
}

output "email_configuration_set_name" {
  value = aws_sesv2_configuration_set.email.configuration_set_name
}

output "email_identity_arn" {
  value = aws_sesv2_email_identity.sender.arn
}

output "verified_sender_email_arn" {
  value = aws_sesv2_email_identity.sender.verified_for_sending_status ? aws_sesv2_email_identity.sender.arn : null
}

output "verified_for_sending_status" {
  value = aws_sesv2_email_identity.sender.verified_for_sending_status
}
