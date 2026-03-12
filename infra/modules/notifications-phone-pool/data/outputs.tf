output "phone_pool_arn" {
  description = "The ARN of the existing SMS phone pool."
  value       = data.external.existing_pools.result.pool_arn
}

output "phone_pool_id" {
  description = "The ID of the existing SMS phone pool."
  value       = data.external.existing_pools.result.pool_id
}

output "pool_exists" {
  description = "Whether an existing phone pool was found."
  value       = data.external.existing_pools.result.exists == "true"
}