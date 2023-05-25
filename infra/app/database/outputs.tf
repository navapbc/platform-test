output "access_policy_arn" {
  value       = module.database.access_policy_arn
  description = "The ARN of the IAM policy that allows access to the database. Attach to an IAM role to grant access to the database."
}

output "cluster_security_group_id" {
  value       = module.database.cluster_security_group_id
  description = "The ID of the security group for the database cluster. Add ingress rules to allow network access to the database."
}

output "role_manager_function_name" {
  value       = module.database.role_manager_function_name
  description = "The name of the Lambda function that manages PostgreSQL database roles. Invoke this function to create or update database roles."
}

output "connection_info" {
  value       = module.database.connection_info
  description = "A map of key value pairs with database connection information (host, port, user, and PostgreSQL database name). Set as environment variables to provide application service with database credentials."
}
