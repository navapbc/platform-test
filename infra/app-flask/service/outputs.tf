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
  value = local.document_data_extraction_config != null ? local.document_data_extraction_config.input_bucket_name : null
}

output "dde_output_bucket_name" {
  value = local.document_data_extraction_config != null ? local.document_data_extraction_config.output_bucket_name : null
}

output "dde_project_arn" {
  value = local.document_data_extraction_config != null ? module.dde[0].bda_project_arn : null
}

output "dde_access_policy_arn" {
  description = "IAM policy ARN for invoking document data extraction"
  value       = local.document_data_extraction_config != null ? module.dde[0].access_policy_arn : null
}

output "dde_blueprint_arns" {
  description = "List of blueprint ARNs for document processing"
  value       = local.document_data_extraction_config != null ? module.dde[0].bda_blueprint_arns : null
}

output "dde_blueprint_names" {
  description = "List of blueprint names for document processing"
  value       = local.document_data_extraction_config != null ? module.dde[0].bda_blueprint_names : null
}

output "bda_blueprint_arn_to_name" {
  description = "Map of blueprint arns to blueprint names for document processing"
  value       = local.document_data_extraction_config != null ? module.dde[0].bda_blueprint_arn_to_name : null
}

