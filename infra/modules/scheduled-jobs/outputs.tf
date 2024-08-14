output "access_policy_arn" {
  description = "Policy that allows access to query feature flag values"
  value       = aws_iam_policy.access_policy.arn
}
