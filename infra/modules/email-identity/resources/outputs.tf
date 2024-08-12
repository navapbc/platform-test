output "dkim_dns_verification_records" {
  value = module.email_identity_data.dkim_dns_verification_records
}

output "dkim_status" {
  value = module.email_identity_data.dkim_status
}

output "email_configuration_set_name" {
  value = aws_sesv2_configuration_set.email.configuration_set_name
}

output "email_identity_arn" {
  value = module.email_identity_data.email_identity_arn
}

output "verified_email_identity_arn" {
  value = module.email_identity_data.verified_email_identity_arn
}

output "verified_for_sending_status" {
  value = module.email_identity_data.verified_for_sending_status
}
