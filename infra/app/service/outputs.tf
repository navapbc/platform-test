output "application_log_group" {
  value = module.service.application_log_group
}

output "application_log_stream_prefix" {
  value = module.service.application_log_stream_prefix
}

output "email_dkim_dns_verification_records" {
  value = module.app_config.enable_notifications ? module.email_identity[0].dkim_dns_verification_records : []
}

output "email_dkim_status" {
  value = module.app_config.enable_notifications ? module.email_identity[0].dkim_status : ""
}

output "email_verified_for_sending_status" {
  value = module.app_config.enable_notifications ? module.email_identity[0].verified_for_sending_status : false
}

output "migrator_role_arn" {
  value = module.service.migrator_role_arn
}

output "service_cluster_name" {
  value = module.service.cluster_name
}

output "service_endpoint" {
  description = "The public endpoint for the service."
  value       = module.service.public_endpoint
}

output "service_name" {
  value = local.service_config.service_name
}
