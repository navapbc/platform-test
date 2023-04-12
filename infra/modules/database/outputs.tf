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
