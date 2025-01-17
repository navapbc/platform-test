locals {
  # The prefix is used to create uniquely named resources per terraform workspace, which
  # are needed in CI/CD for preview environments and tests.
  #
  # To isolate changes during infrastructure development by using manually created
  # terraform workspaces, see: /docs/infra/develop-and-test-infrastructure-in-isolation-using-workspaces.md
  prefix = terraform.workspace == "default" ? "" : "${terraform.workspace}-"

  # Add environment specific tags
  tags = merge(module.project_config.default_tags, {
    environment = var.environment_name
    description = "Application resources created in ${var.environment_name} environment"
  })

  # All non-default terraform workspaces are considered temporary.
  # Temporary environments do not have deletion protection enabled.
  # Examples: pull request preview environments are temporary.
  is_temporary = terraform.workspace != "default"

  build_repository_config = module.app_config.build_repository_config
  environment_config      = module.app_config.environment_configs[var.environment_name]
  service_config          = local.environment_config.service_config

  service_name = "${local.prefix}${local.service_config.service_name}"
}

terraform {
  required_version = "~>1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.81.0, < 6.0.0"
    }
  }

  backend "s3" {
    encrypt = "true"
  }
}

provider "aws" {
  region = local.service_config.region
  default_tags {
    tags = local.tags
  }
}

module "project_config" {
  source = "../../project-config"
}

module "app_config" {
  source = "../app-config"
}

module "service" {
  source       = "../../modules/service"
  service_name = local.service_name

  image_repository_arn = local.build_repository_config.repository_arn
  image_repository_url = local.build_repository_config.repository_url

  image_tag = local.image_tag

  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  domain_name     = local.domain_config.domain_name
  hosted_zone_id  = module.domain.hosted_zone_id
  certificate_arn = module.domain.certificate_arn

  cpu                      = local.service_config.cpu
  memory                   = local.service_config.memory
  desired_instance_count   = local.service_config.desired_instance_count
  enable_command_execution = local.service_config.enable_command_execution

  aws_services_security_group_id = data.aws_security_groups.aws_services.ids[0]

  file_upload_jobs = local.service_config.file_upload_jobs
  scheduled_jobs   = local.environment_config.scheduled_jobs

  db_vars = module.app_config.has_database ? {
    security_group_ids         = data.aws_rds_cluster.db_cluster[0].vpc_security_group_ids
    app_access_policy_arn      = data.aws_iam_policy.app_db_access_policy[0].arn
    migrator_access_policy_arn = data.aws_iam_policy.migrator_db_access_policy[0].arn
    connection_info = {
      host        = data.aws_rds_cluster.db_cluster[0].endpoint
      port        = data.aws_rds_cluster.db_cluster[0].port
      user        = local.database_config.app_username
      db_name     = data.aws_rds_cluster.db_cluster[0].database_name
      schema_name = local.database_config.schema_name
    }
  } : null

  extra_environment_variables = merge(
    {
      BUCKET_NAME = local.bucket_name
    },
    local.identity_provider_environment_variables,
    local.notifications_environment_variables,
    local.service_config.extra_environment_variables
  )

  secrets = concat(
    [for secret_name in keys(local.service_config.secrets) : {
      name      = secret_name
      valueFrom = module.secrets[secret_name].secret_arn
    }],
    module.app_config.enable_identity_provider ? [{
      name      = "COGNITO_CLIENT_SECRET"
      valueFrom = module.identity_provider_client[0].client_secret_arn
    }] : []
  )

  extra_policies = merge(
    {
      storage_access = module.storage.access_policy_arn
    },
    module.app_config.enable_identity_provider ? {
      identity_provider_access = module.identity_provider_client[0].access_policy_arn,
    } : {},
    module.app_config.enable_notifications ? {
      notifications_access = module.notifications[0].access_policy_arn,
    } : {},
  )

  is_temporary = local.is_temporary
}
