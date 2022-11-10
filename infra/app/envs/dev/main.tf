data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  environment_name = "dev"

  # Choose the region where this infrastructure should be deployed.
  region = "us-east-1"
  # Add environment specific tags
  tags = merge(module.project_config.default_tags, {
    environment = local.environment_name
    description = "Application resources created in dev environment"
  })

  tfstate_bucket = "platform-test-430004246987-us-east-1-tf-state"
  tfstate_key    = "infra/app/environments/dev.tfstate"
}

terraform {
  required_version = ">=1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.20.1"
    }
  }

  # Terraform does not allow interpolation here, values must be hardcoded.

  backend "s3" {
    bucket         = "platform-test-430004246987-us-east-1-tf-state"
    key            = "infra/app/environments/dev.tfstate"
    dynamodb_table = "platform-test-tf-state-locks"
    region         = "us-east-1"
    encrypt        = "true"
  }
}

provider "aws" {
  region = local.region
  default_tags {
    tags = local.tags
  }
}

module "project_config" {
  source = "../../../project-config"
}

module "app" {
  source           = "../../env-template"
  environment_name = local.environment_name
  image_tag        = local.image_tag
}
