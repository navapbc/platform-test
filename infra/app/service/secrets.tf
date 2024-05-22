module "secrets" {
  for_each = local.service_config.secrets

  source = "../../modules/secret"

  # Append the terraform workspace to the secret store path if the environment is temporary
  # to avoid conflicts with existing environments
  secret_store_path = (local.is_temporary ?
    "${each.value.secret_store_path}/${terraform.workspace}" :
    each.value.secret_store_path
  )
  manage_method = each.value.manage_method
}
