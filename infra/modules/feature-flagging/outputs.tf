output "evidently_project_name" {
  description = "Name of feature flag manager"
  value       = local.evidently_project_name
}

output "access_policy_arn" {
  description = "Policy that allows access to query feature flag values"
  value       = data.aws_iam_policy.access_policy.arn
}
