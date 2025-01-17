locals {
  network_config     = module.project_config.network_configs[local.environment_config.network_name]
}

data "aws_vpc" "network" {
  tags = {
    project      = module.project_config.project_name
    network_name = local.environment_config.network_name
  }
}

data "aws_subnets" "database" {
  tags = {
    project      = module.project_config.project_name
    network_name = local.environment_config.network_name
    subnet_type  = "database"
  }
}

