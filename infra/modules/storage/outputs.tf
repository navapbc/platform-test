output "access_policy_arn" {
  value = aws_iam_policy.storage_access.arn
}

output "bucket_arn" {
  value = aws_s3_bucket.storage.arn
}