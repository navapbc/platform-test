# TODO(https://github.com/navapbc/template-infra/issues/152) use non-default VPC
data "aws_vpc" "default" {
  default = true
}

# TODO(https://github.com/navapbc/template-infra/issues/152) use private subnets
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = [true]
  }
}


locals {
  # The prefix key/value pair is used for Terraform Workspaces, which is useful for projects with multiple infrastructure developers.
  # By default, Terraform creates a workspace named “default.” If a non-default workspace is not created this prefix will equal “default”, 
  # if you choose not to use workspaces set this value to "dev" 
  prefix = terraform.workspace == "default" ? "" : "${terraform.workspace}-"

  # Add environment specific tags
  tags = merge(module.project_config.default_tags, {
    environment = var.environment_name
    description = "Application resources created in ${var.environment_name} environment"
  })

  service_name = "${local.prefix}${module.app_config.app_name}-${var.environment_name}"
}

terraform {
  required_version = ">=1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.20.1"
    }
  }

  backend "s3" {
    encrypt = "true"
  }
}

provider "aws" {
  region = var.region
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
  source                = "../../modules/service"
  service_name          = local.service_name
  image_repository_name = module.app_config.image_repository_name
  image_tag             = local.image_tag
  vpc_id                = data.aws_vpc.default.id
  subnet_ids            = data.aws_subnets.default.ids

  # TODO add these variables from database output
  # service_policy_arns = [var.db_access_policy_arn]
  # env_vars            = var.db_service_env_vars
}

moved {
  from = module.app.module.service.aws_cloudwatch_log_group.service_logs
  to   = module.service.aws_cloudwatch_log_group.service_logs
}

moved {
  from = module.app.module.service.aws_ecs_cluster.cluster
  to   = module.service.aws_ecs_cluster.cluster
}

moved {
  from = module.app.module.service.aws_ecs_service.app
  to   = module.service.aws_ecs_service.app
}

moved {
  from = module.app.module.service.aws_ecs_task_definition.app
  to   = module.service.aws_ecs_task_definition.app
}

moved {
  from = module.app.module.service.aws_iam_role.task_executor
  to   = module.service.aws_iam_role.task_executor
}

moved {
  from = module.app.module.service.aws_iam_role_policy.task_executor
  to   = module.service.aws_iam_role_policy.task_executor
}

moved {
  from = module.app.module.service.aws_lb.alb
  to   = module.service.aws_lb.alb
}

moved {
  from = module.app.module.service.aws_lb_listener.alb_listener_http
  to   = module.service.aws_lb_listener.alb_listener_http
}

moved {
  from = module.app.module.service.aws_lb_listener_rule.app_http_forward
  to   = module.service.aws_lb_listener_rule.app_http_forward
}

moved {
  from = module.app.module.service.aws_lb_target_group.app_tg
  to   = module.service.aws_lb_target_group.app_tg
}

moved {
  from = module.app.module.service.aws_security_group.alb
  to   = module.service.aws_security_group.alb
}

moved {
  from = module.app.module.service.aws_security_group.app
  to   = module.service.aws_security_group.app
}

