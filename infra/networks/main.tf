# TODO: This file is is a temporary implementation of the network layer
# that currently just adds resources to the default VPC
# The full network implementation is part of https://github.com/navapbc/template-infra/issues/152
locals {
  tags = merge(module.project_config.default_tags, {
    description = "VPC resources"
  })
  region = module.project_config.default_region
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

data "aws_vpc" "default" {
  default = true
}

# VPC Endpoints for accessing AWS Services
# ----------------------------------------
#
# Since the role manager Lambda function is in the VPC (which is needed to be
# able to access the database) we need to allow the Lambda function to access
# AWS Systems Manager Parameter Store (to fetch the database password) and
# KMS (to decrypt SecureString parameters from Parameter Store). We can do
# this by either allowing internet access to the Lambda, or by using a VPC
# endpoint. The latter is more secure.
# See https://repost.aws/knowledge-center/lambda-vpc-parameter-store
# See https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html#create-interface-endpoint

aws_services = []

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = var.private_subnet_ids
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = var.private_subnet_ids
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.rds"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  subnet_ids          = var.private_subnet_ids
  private_dns_enabled = true
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name}-vpc-endpoints"
  description = "VPC endpoints to access SSM and KMS"
  vpc_id      = data.aws_vpc.default.id
}
