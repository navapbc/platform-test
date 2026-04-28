data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  document_data_extraction_config = local.environment_config.document_data_extraction_config

  # bda region must be hardcoded here to avoid circular dependency.
  # Provider configurations must be known at plan time, but 
  # local.document_data_extraction_config.bda_region depends on module outputs.
  # bda is only available in us-east-1, us-west-2, and us-gov-west-1.
  bda_region                       = "us-east-1"
  job_id_index_name                = "jobId-index"
  tenant_index_name                = "tenantId-index"
  external_reference_id_index_name = "externalReferenceId-index"
  batch_id_index_name              = "batchId-index"
  build_id_index_name              = "buildId-index"
  max_batch_size                   = 50
  max_bda_invoke_retry_attempts    = 3

  document_data_extraction_environment_variables = local.document_data_extraction_config != null ? {
    DOCUMENTAI_INPUT_LOCATION                         = "s3://${local.prefix}${local.document_data_extraction_config.input_bucket_name}/input"
    DOCUMENTAI_PREPROCESSING_LOCATION                 = "s3://${local.prefix}${local.document_data_extraction_config.input_bucket_name}/preprocessing"
    DOCUMENTAI_OUTPUT_LOCATION                        = "s3://${local.prefix}${local.document_data_extraction_config.output_bucket_name}/processed"
    DOCUMENTAI_DOCUMENT_METADATA_TABLE_NAME           = "${local.prefix}${local.document_data_extraction_config.document_metadata_table_name}"
    DOCUMENTAI_BUILD_TABLE_NAME                       = "${local.prefix}${local.document_data_extraction_config.document_build_table_name}"
    DOCUMENTAI_BATCH_TABLE_NAME                       = "${local.prefix}${local.document_data_extraction_config.batch_table_name}"
    DOCUMENTAI_DOCUMENT_METADATA_JOB_ID_INDEX_NAME    = local.job_id_index_name
    DOCUMENTAI_DOCUMENT_METADATA_TENANT_ID_INDEX_NAME = local.tenant_index_name
    DOCUMENTAI_DOCUMENT_METADATA_BATCH_ID_INDEX_NAME  = local.batch_id_index_name
    DOCUMENTAI_DOCUMENT_METADATA_BUILD_ID_INDEX_NAME  = local.build_id_index_name
    DOCUMENTAI_EXTERNAL_REF_ID_INDEX_NAME             = local.external_reference_id_index_name
    DOCUMENTAI_MAX_BATCH_SIZE                         = local.max_batch_size
    BDA_PROJECT_ARN                                   = module.documentai[0].bda_project_arn
    BDA_REGION                                        = local.bda_region
    MAX_BDA_INVOKE_RETRY_ATTEMPTS                     = local.max_bda_invoke_retry_attempts

    # aws bedrock data automation requires users to use cross Region inference support 
    # when processing files. the following like the profile ARNs for different inference
    # profiles
    # https://docs.aws.amazon.com/bedrock/latest/userguide/bda-cris.html
    BDA_PROFILE_ARN = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1"

  } : {}
}

provider "aws" {
  alias  = "documentai"
  region = local.bda_region
}

provider "awscc" {
  alias  = "documentai"
  region = local.bda_region
}

module "documentai_input_bucket" {
  providers = {
    aws = aws.documentai
  }

  count                          = local.document_data_extraction_config != null ? 1 : 0
  source                         = "../../modules/storage"
  name                           = "${local.prefix}${local.document_data_extraction_config.input_bucket_name}"
  is_temporary                   = local.is_temporary
  service_principals_with_access = ["bedrock.amazonaws.com"]
}

module "documentai_output_bucket" {
  providers = {
    aws = aws.documentai
  }

  count                          = local.document_data_extraction_config != null ? 1 : 0
  source                         = "../../modules/storage"
  name                           = "${local.prefix}${local.document_data_extraction_config.output_bucket_name}"
  is_temporary                   = local.is_temporary
  service_principals_with_access = ["bedrock.amazonaws.com"]
}

module "documentai" {
  providers = {
    aws   = aws.documentai
    awscc = awscc.documentai
  }

  count  = local.document_data_extraction_config != null ? 1 : 0
  source = "../../modules/document-data-extraction/resources"

  standard_output_configuration = local.document_data_extraction_config.standard_output_configuration
  tags                          = local.tags

  blueprints = concat(
    # Custom blueprints from files
    [for blueprint in fileset(local.document_data_extraction_config.custom_blueprints_path, "*") :
      "${local.document_data_extraction_config.custom_blueprints_path}/${blueprint}"
    ],
    # AWS managed blueprint ARNs
    local.document_data_extraction_config.aws_managed_blueprints != null ?
    local.document_data_extraction_config.aws_managed_blueprints : []
  )

  name = "${local.prefix}${local.document_data_extraction_config.name}"
}

#-------------------
# KMS Key for DynamoDB Encryption
#-------------------
data "aws_iam_policy_document" "dynamodb_kms_key_policy" {
  #checkov:skip=CKV_AWS_109:Root account requires full KMS permissions to enable IAM-based access control
  #checkov:skip=CKV_AWS_111:Root account requires full KMS permissions to enable IAM-based access control
  #checkov:skip=CKV_AWS_356:Wildcard in Resource element represents the KMS key to which the key policy is attached

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

  policy = data.aws_iam_policy_document.dynamodb_kms_key_policy.json

  tags = local.tags
}

#-------------------
# Storage Resources
#-------------------
resource "aws_dynamodb_table" "document_metadata" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name         = "${local.prefix}${local.document_data_extraction_config.document_metadata_table_name}"
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

  attribute {
    name = "tenantId"
    type = "S"
  }

  attribute {
    name = "externalReferenceId"
    type = "S"
  }

  attribute {
    name = "batchId"
    type = "S"
  }

  attribute {
    name = "buildId"
    type = "S"
  }

  attribute {
    name = "createdAt"
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

  global_secondary_index {
    name            = local.tenant_index_name
    hash_key        = "tenantId"
    range_key       = "createdAt" # Sort by createdAt timestamp
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = local.external_reference_id_index_name
    hash_key        = "externalReferenceId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = local.batch_id_index_name
    hash_key        = "batchId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = local.build_id_index_name
    hash_key        = "buildId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb[0].arn
  }

  point_in_time_recovery {
    enabled = true
  }


  tags = local.tags
}

resource "aws_dynamodb_table" "document_builds" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name         = "${local.prefix}${local.document_data_extraction_config.document_build_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "buildId"

  range_key = "pageNumber"

  attribute {
    name = "buildId"
    type = "S"
  }
  attribute {
    name = "pageNumber"
    type = "N"
  }

  attribute {
    name = "tenantId"
    type = "S"
  }

  attribute {
    name = "externalReferenceId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = local.tenant_index_name
    hash_key        = "tenantId"
    range_key       = "createdAt" # Sort by createdAt timestamp
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = local.external_reference_id_index_name
    hash_key        = "externalReferenceId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb[0].arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.tags
}

resource "aws_dynamodb_table" "document_batches" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name         = "${local.prefix}${local.document_data_extraction_config.batch_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "batchId"

  attribute {
    name = "batchId"
    type = "S"
  }

  attribute {
    name = "tenantId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "StatusCreatedAtIndex"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = local.tenant_index_name
    hash_key        = "tenantId"
    range_key       = "createdAt" # Sort by createdAt timestamp
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb[0].arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.tags
}

#-------------------
# Bedrock Classification Config (SSM)
#-------------------
resource "aws_ssm_parameter" "bedrock_classification_model_id" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name  = "/service/${local.service_name}/bedrock/classification-model-id"
  type  = "String"
  value = "anthropic.claude-3-haiku-20240307-v1:0"

  lifecycle {
    ignore_changes = [value]
  }
}

# <<DOCUMENT_TYPES>> in the classification prompt needs to be dynamically 
# replaced with the document types that BDA is configured to extract. Store prompt 
# in SSM Parameter Store; application reads and update it at runtime.
resource "aws_ssm_parameter" "bedrock_classification_prompt" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name  = "/service/${local.service_name}/bedrock/classification-prompt"
  type  = "String"
  value = <<-EOT
Analyze this image. Respond in JSON only:
{"document_type": "string", "confidence": float 0-1, "document_count": int}
ONLY use one of these exact values for document_type: <<DOCUMENT_TYPES>>
Do not create new categories. If unsure, use 'other_document'.
If it's not a document, use 'not_a_document'.
document_count: how many separate documents are visible in this image?
EOT

  lifecycle {
    ignore_changes = [value]
  }
}


#-------------------
# IAM Policies
#-------------------
resource "aws_iam_policy" "dynamodb_read_write" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.prefix}dynamodb-read-write"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:BatchWriteItem", "dynamodb:DeleteItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
        "dynamodb:BatchGetItem", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"
      ]
      Resource = [
        aws_dynamodb_table.document_metadata[0].arn,
        "${aws_dynamodb_table.document_metadata[0].arn}/index/*",
        aws_dynamodb_table.document_builds[0].arn,
        "${aws_dynamodb_table.document_builds[0].arn}/index/*",
        aws_dynamodb_table.document_batches[0].arn,
        "${aws_dynamodb_table.document_batches[0].arn}/index/*"
      ]
      Effect = "Allow"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.dynamodb[0].arn
        Effect   = "Allow"
    }]
  })
}

resource "aws_iam_policy" "bedrock_data_automation_invoke" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.prefix}bedrock-invoke"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "bedrock:InvokeDataAutomationAsync"
      Resource = [
        module.documentai[0].bda_project_arn,
        local.document_data_extraction_environment_variables.BDA_PROFILE_ARN,
        "arn:aws:bedrock:us-east-2:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1",
        "arn:aws:bedrock:us-west-1:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1",
        "arn:aws:bedrock:us-west-2:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1"
      ]
      Effect = "Allow"
    }]
  })
}


resource "aws_iam_policy" "bedrock_runtime_invoke" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.prefix}bedrock-runtime-invoke"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/*"
        Effect   = "Allow"
      },
      {
        Action = "ssm:GetParameter"
        Resource = [
          aws_ssm_parameter.bedrock_classification_model_id[0].arn,
          aws_ssm_parameter.bedrock_classification_prompt[0].arn,
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "textract_analyze_id" {
  count = local.document_data_extraction_config != null ? 1 : 0

  name = "${local.prefix}textract-analyze-id"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "textract:AnalyzeID"
      Resource = "*"
      Effect   = "Allow"
    }]
  })
}
