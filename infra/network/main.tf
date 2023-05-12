locals {
  # Set project tags that will be used to tag all resources. 
  tags = merge(module.project_config.default_tags, {
    description = "Network resources such as security groups, VPCs, subnets, etc."
  })
}

terraform {

  required_version = "~>1.2.0"

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
  source = "../project-config"
}

resource "aws_security_group" "public_load_balancer" {
  name_prefix = "${module.project_config.project_name}-pub-lb"
}

resource "aws_security_group" "private_service" {
  name_prefix = "${module.project_config.project_name}-pvt-app-"
}

resource "aws_security_group" "private_database" {
  name_prefix = "${module.project_config.project_name}-pvt-db-"
}
