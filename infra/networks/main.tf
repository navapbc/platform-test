# TODO: This file is is a temporary implementation of the network layer
# that currently just adds resources to the default VPC
# The full network implementation is part of https://github.com/navapbc/template-infra/issues/152

locals {
  tags = merge(module.project_config.default_tags, {
    network_name = var.network_name
    description  = "VPC resources"
  })
  region = module.project_config.default_region

  network_config = module.project_config.network_configs[var.network_name]

  # If project has multiple apps, add other app configs to this list
  app_configs = [module.app_config]
  apps_using_network = [
    for app_config in local.app_configs :
    app_config
    if anytrue([
      for environment_config in app_config.environment_configs : true if environment_config.network_name == var.network_name
    ])
  ]
  has_database = anytrue([for app_config in local.apps_using_network : app_config.has_database])
}

terraform {
  required_version = ">= 1.2.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.6.0"
    }
  }

  backend "s3" {
    encrypt = "true"
  }
}

provider "aws" {
  region = local.region
  default_tags {
    tags = local.tags
  }
}

module "project_config" {
  source = "../project-config"
}

module "app_config" {
  source = "../app/app-config"
}

module "network" {
  source                                  = "../modules/network"
  name                                    = var.network_name
  aws_services_security_group_name_prefix = module.project_config.aws_services_security_group_name_prefix
  database_subnet_group_name              = local.network_config.database_subnet_group_name
  nat_gateway_config                      = "none"
}
