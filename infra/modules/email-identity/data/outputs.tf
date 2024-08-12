output "dkim_dns_verification_records" {
  value = local.dkim_dns_verification_records
}

output "dkim_status" {
  value = var.email_verification_method == "email" ? "" : data.aws_sesv2_email_identity.sender.dkim_signing_attributes[0].status
}

output "email_configuration_set_name" {
  value = var.name
}

output "email_identity_arn" {
  value = data.aws_sesv2_email_identity.sender.arn
}

output "verified_email_identity_arn" {
  value = data.aws_sesv2_email_identity.sender.verified_for_sending_status ? data.aws_sesv2_email_identity.sender.arn : null
}

output "verified_for_sending_status" {
  value = data.aws_sesv2_email_identity.sender.verified_for_sending_status
}
