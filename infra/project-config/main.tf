locals {
  # Machine readable project name (lower case letters, dashes, and underscores)
  # This will be used in names of AWS resources
  project_name = "platform-test"

  # Project owner (e.g. navapbc). Used for tagging infra resources.
  owner = "platform-admins"

  # URL of project source code repository
  code_repository_url = "git@github.com:navapbc/platform-test.git"

  # Default AWS region for project (e.g. us-east-1, us-east-2, us-west-1).
  # This is dependent on where your project is located (if regional)
  # otherwise us-east-1 is a good default
  default_region = "us-east-1"

  # List of AWS regions that may be used for this project.
  # Used for multi-region deployments or to scope down other resources that need to interact with multiple regions.
  # TODO: When upgrading to AWS provider >= 5.7.0, update to include all regions that GuardDuty should be enabled in for multi-region support:
  # Ticket: https://github.com/navapbc/template-infra/issues/1004#issue-4083076747
  #regions = [local.default_region]

  github_actions_role_name = "${local.project_name}-github-actions"

}
