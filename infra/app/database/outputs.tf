output "access_policy_arn" {
  value = module.database.access_policy_arn
}

output "cluster_security_group_id" {
  value = module.database.cluster_security_group_id
}

output "role_manager_function_name" {
  value = module.database.role_manager_function_name
}

output "service_env_vars" {
  value = module.database.service_env_vars
}
