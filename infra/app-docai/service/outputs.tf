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

output "metrics_queue_url" {
  value = local.document_data_extraction_config != null ? aws_sqs_queue.dde_job_completion_metrics[0].url : null
}

output "metrics_bucket_name" {
  value = local.document_data_extraction_config != null ? module.dde_metrics_data_bucket[0].bucket_name : null
}
