output "database_host" {
  value = aws_rds_cluster.db.endpoint
}

output "database_name" {
  value = aws_rds_cluster.db.database_name
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

output "service_env_vars" {
  value = {
    DB_HOST = aws_rds_cluster.db.endpoint
    DB_NAME = aws_rds_cluster.db.database_name
    DB_USER = local.app_username
  }
}
