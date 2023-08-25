locals {
  # Machine readable project name (lower case letters, dashes, and underscores)
  project_name = "platform-test"

  # Project owner
  owner = "platform-admins"

  # URL of project source code repository
  code_repository_url = "git@github.com:navapbc/platform-test.git"

  # Default AWS region for project (e.g. us-east-1, us-east-2, us-west-1)
  default_region = "us-east-1"

  github_actions_role_name = "${local.project_name}-github-actions"

  vpc_endpoints_security_group_name = "aws-service-vpc-endpoints"
}
