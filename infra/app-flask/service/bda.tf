data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "input_policy" {
  bucket = aws_s3_bucket.input.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/bda_module_test-bda_role"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.input.arn,
          "${aws_s3_bucket.input.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "output_policy" {
  bucket = aws_s3_bucket.output.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/bda_module_test-bda_role"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.output.arn,
          "${aws_s3_bucket.output.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket" "input" {
  bucket        = "app-flask-bda-test-input-bucket"
  force_destroy = true
}

resource "aws_s3_bucket" "output" {
  bucket        = "app-flask-bda-test-output-bucket"
  force_destroy = true
}

module "bda_test" {
  source = "../../modules/bedrock-data-automation"

  bda_standard_output_configuration = {
    image = {
      extraction = {
        bounding_box = {
          state = "ENABLED"
        }
        category = {
          state = "ENABLED"
          types = ["TEXT_DETECTION", "LOGOS"]
        }
      }
      generative_field = {
        state = "ENABLED"
        types = ["IMAGE_SUMMARY"]
      }
    }
  }

  blueprints_map = {
    "drivers_license" = {
      schema                 = file("blueprints/template_blueprint.json")
      type                   = "DOCUMENT"
      kms_encryption_context = null
      kms_key_id             = null
      tags                   = [{ key = "example_tag_key", value = "example_tag_value" }]
    }
  }
  name_prefix       = "bda_module_test"
  input_bucket_arn  = aws_s3_bucket.input.arn
  output_bucket_arn = aws_s3_bucket.output.arn
}
