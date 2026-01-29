output "access_policy_arn" {
  value = aws_iam_policy.storage_access.arn
}

output "kms_key_arn" {
  value = var.use_aws_managed_encryption ? null : aws_kms_key.storage[0].arn
}
