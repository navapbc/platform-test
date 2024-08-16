data "external" "account_ids_by_name" {
  program = ["../../../bin/account-ids-by-name"]
}

locals {
  shared_account_name = module.project_config.network_configs[local.shared_network_name].account_name
  shared_account_id   = data.external.account_ids_by_name.result[local.shared_account_name]

  build_repository_config = {
    name         = "${local.project_name}-${local.app_name}"
    region       = module.project_config.default_region
    network_name = local.shared_network_name
    account_name = local.shared_account_name
    account_id   = local.shared_account_id
  }
}
