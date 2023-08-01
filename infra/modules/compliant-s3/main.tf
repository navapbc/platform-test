resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${var.service_name}-${var.purpose}"
  force_destroy = false
  # checkov:skip=CKV2_AWS_62:Ensure S3 buckets should have event notifications enabled
  # checkov:skip=CKV_AWS_18:Ensure the S3 bucket has access logging enabled
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_replication_configuration" "rep_config" {
  
# }

# resource "aws_s3_bucket_lifecycle_configuration" "lc" {
#   count = var.log_file_transition != [] || var.log_file_deletion !=0 ? 1 : 0
#   bucket =   aws_s3_bucket.bucket.id
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

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "bucket_pol" {
  bucket = aws_s3_bucket.bucket.id
  policy = var.bucket_policy_document
}