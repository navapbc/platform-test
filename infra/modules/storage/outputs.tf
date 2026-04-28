output "access_policy_arn" {
  value = aws_iam_policy.storage_access.arn
}

output "bucket_name" {
  value = aws_s3_bucket.storage.id
}

output "bucket_arn" {
  value = aws_s3_bucket.storage.arn
}

output "kms_key_arn" {
  value = aws_kms_key.storage.arn
}
