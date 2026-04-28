# documentai_api.tf - App-specific resources for DocumentAI API

data "aws_caller_identity" "current" {}

locals {
  documentai_api_config         = local.environment_config.documentai_api_config
  job_id_index_name             = "jobId-index"
  max_bda_invoke_retry_attempts = 3

  documentai_api_environment_variables = local.document_data_extraction_config != null ? {
    # Alias standard DDE env vars
    #
    # TODO(pre-merge): create ticket for documentapi-api to respect standard DDE env vars
    # and/or update DDE module to provide other env vars (like the BDA_ ones?)
    DOCUMENTAI_INPUT_LOCATION  = "${local.document_data_extraction_environment_variables.DDE_INPUT_LOCATION}/input"
    DOCUMENTAI_OUTPUT_LOCATION = "${local.document_data_extraction_environment_variables.DDE_OUTPUT_LOCATION}/processed"
    BDA_PROJECT_ARN            = local.document_data_extraction_environment_variables.DDE_PROJECT_ARN
    BDA_PROFILE_ARN            = local.document_data_extraction_environment_variables.DDE_PROFILE_ARN

    # TODO(pre-merge): create ticket for documentai-api to just extract this from the
    # profile ARN? Or for the DDE module to provide standard env var.
    BDA_REGION = local.document_data_extraction_config.bda_region

    DOCUMENTAI_DOCUMENT_METADATA_TABLE_NAME        = aws_dynamodb_table.document_metadata[0].name
    DOCUMENTAI_DOCUMENT_METADATA_JOB_ID_INDEX_NAME = local.job_id_index_name
    MAX_BDA_INVOKE_RETRY_ATTEMPTS                  = local.max_bda_invoke_retry_attempts
  } : {}
}

# KMS Key for DynamoDB Encryption
data "aws_iam_policy_document" "dynamodb_kms_key_policy" {
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_356

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "dynamodb" {
  count = local.document_data_extraction_config != null ? 1 : 0

  description             = "KMS key for DocumentAI DynamoDB tables"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.dynamodb_kms_key_policy.json
}

resource "aws_dynamodb_table" "document_metadata" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name         = "${local.prefix}${local.documentai_api_config.document_metadata_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "fileName"

  attribute {
    name = "fileName"
    type = "S"
  }

  attribute {
    name = "jobId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = local.job_id_index_name
    hash_key        = "jobId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb[0].arn
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_iam_policy" "dynamodb_read_write" {
  count  = local.document_data_extraction_config != null ? 1 : 0
  name   = "${local.service_name}-document-metadata-table-access"
  policy = data.aws_iam_policy_document.dynamodb_read_write.json
}

data "aws_iam_policy_document" "dynamodb_read_write" {
  statement {
    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
    resources = [
      aws_dynamodb_table.document_metadata[0].arn,
      "${aws_dynamodb_table.document_metadata[0].arn}/index/*"
    ]
    effect = "Allow"

  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.dynamodb[0].arn]
    effect    = "Allow"
  }
}
