output "database_host" {
  value = aws_rds_cluster.db.endpoint
}

output "database_port" {
  value = aws_rds_cluster.db.port
}

output "database_name" {
  value = aws_rds_cluster.db.database_name
}

output "database_security_group_id" {
  description = "The ID of the security group for the database."
  value       = aws_security_group.db.id
}

output "app_username" {
  value = local.app_username
}

output "migrator_username" {
  value = local.migrator_username
}

output "schema_name" {
  value = local.schema_name
}

output "access_policy_arn" {
  value = aws_iam_policy.db_access.arn
}

output "service_env_vars" {
  value = {
    DB_HOST = aws_rds_cluster.db.endpoint
    DB_PORT = aws_rds_cluster.db.port
    DB_NAME = aws_rds_cluster.db.database_name
    DB_USER = local.app_username
  }
}
