output "access_policy_arn" {
  value = aws_iam_policy.storage_access.arn
}

output "bucket_arn" {
  value = aws_s3_bucket.storage.arn
}

output "bucket_name" {
  value = aws_s3_bucket.storage.bucket
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = var.use_aws_managed_encryption ? null : aws_kms_key.storage[0].arn
}