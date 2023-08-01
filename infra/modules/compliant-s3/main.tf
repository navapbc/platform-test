resource "aws_s3_bucket" "load_balancer_logs" {
  bucket_prefix = "${var.prefix}${var.service_name}-access-logs"
  force_destroy = false
  # checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  # checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
}

resource "aws_s3_bucket_public_access_block" "load_balancer_logs" {
  bucket = aws_s3_bucket.load_balancer_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_replication_configuration" "load_balancer_logs" {
  
# }

# resource "aws_s3_bucket_lifecycle_configuration" "load_balancer_logs" {
#   count = var.log_file_transition != [] || var.log_file_deletion !=0 ? 1 : 0
#   bucket =   aws_s3_bucket.load_balancer_logs.id
#   rule {
#     id = "Logfile Lifecycle"
#     filter {
#       prefix = "${var.service_name}-lb"
#       dynamic "transition" {
#         for_each = var.log_file_transition
#         content {

#         }
#       }
#     }
#   }
# }

resource "aws_s3_bucket_versioning" "load_balancer_logs" {
  bucket = aws_s3_bucket.load_balancer_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "load_balancer" {
  bucket = aws_s3_bucket.load_balancer_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "load_balancer_logs_put_access" {
  bucket = aws_s3_bucket.load_balancer_logs.id
  policy = var.bucket_policy_document
}