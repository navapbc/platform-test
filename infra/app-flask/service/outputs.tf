output "application_log_group" {
  value = module.service.application_log_group
}

output "application_log_stream_prefix" {
  value = module.service.application_log_stream_prefix
}

output "migrator_role_arn" {
  value = module.service.migrator_role_arn
}

output "migrator_username" {
  value = module.app_config.has_database ? module.database[0].migrator_username : null
}

output "ses_from_email" {
  value = local.notifications_config != null ? module.notifications[0].from_email : null
}

output "service_cluster_name" {
  value = module.service.cluster_name
}

output "service_endpoint" {
  description = "The public endpoint for the service."
  value       = module.service.public_endpoint
}

output "service_name" {
  value = local.service_name
}

output "dde_input_bucket_name" {
  value = local.document_data_extraction_config != null ? "${local.prefix}${local.document_data_extraction_config.input_bucket_name}" : null
}

output "dde_output_bucket_name" {
  value = local.document_data_extraction_config != null ? "${local.prefix}${local.document_data_extraction_config.output_bucket_name}" : null
}

# aws bedrock data automation requires users to use cross Region inference support 
# when processing files. the following like the profile ARNs for different inference
# profiles
# https://docs.aws.amazon.com/bedrock/latest/userguide/bda-cris.html
output "dde_profile_arn" {
  value = local.document_data_extraction_config != null ? "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1" : null
}

output "dde_project_arn" {
  value = local.document_data_extraction_config != null ? module.dde[0].bda_project_arn : null
}