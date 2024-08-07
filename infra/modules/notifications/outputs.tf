output "application_id" {
  value = aws_pinpoint_app.app.application_id
}

output "dkim_dns_verification_records" {
  value = local.dkim_dns_verification_records
}

output "dkim_status" {
  value = aws_sesv2_email_identity.sender.dkim_signing_attributes.status
}

output "verified_for_sending_status" {
  value = aws_sesv2_email_identity.verified_for_sending_status
}
