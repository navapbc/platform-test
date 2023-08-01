output "bucket_id" {
  value = aws_s3_bucket.load_balancer_logs.id
}

output "bucket_arn" {
  value = aws_s3_bucket.load_balancer_logs.arn
}
