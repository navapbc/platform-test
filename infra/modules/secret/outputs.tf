output "secret_arn" {
  value = local.secret.arn
}

output "access_policy_arn" {
  value = aws_iam_policy.access_policy.arn
}
