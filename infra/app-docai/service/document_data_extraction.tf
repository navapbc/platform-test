data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  document_data_extraction_config = local.environment_config.document_data_extraction_config

  document_data_extraction_environment_variables = local.document_data_extraction_config != null ? {
    DDE_INPUT_LOCATION               = "s3://${local.prefix}${local.document_data_extraction_config.input_bucket_name}"
    DDE_OUTPUT_LOCATION              = "s3://${local.prefix}${local.document_data_extraction_config.output_bucket_name}"
    DDE_DOCUMENT_METADATA_TABLE_NAME = "${local.prefix}${local.document_data_extraction_config.document_metadata_table_name}"
    DDE_PROJECT_ARN                  = module.dde[0].bda_project_arn
    DDE_REGION                       = "us-east-1"  # TODO: update to use dde module region

    # aws bedrock data automation requires users to use cross Region inference support 
    # when processing files. the following like the profile ARNs for different inference
    # profiles
    # https://docs.aws.amazon.com/bedrock/latest/userguide/bda-cris.html
    DDE_PROFILE_ARN = "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1"
  } : {}

  lambda_functions = local.document_data_extraction_config != null ? {
    ddb_insert_file_name = {
      function_name      = "ddb-insert-file-name"
      role_name          = "ddb-insert-role"
      handler            = "handlers.ddb_insert_file_name"
      description        = "Inserts file name into DynamoDB when files are uploaded"
      policies           = ["grantInputBucket", "grantDynamoDb"]
      attachOpenCvLayer  = true
      attachPopplerLayer = true
      timeout_seconds    = 60
    }
    bda_invoker = {
      function_name      = "bda-invoker"
      role_name          = "bda-invoker-role"
      handler            = "handlers.bda_invoker"
      description        = "Invokes BDA job when DynamoDB record is created"
      policies           = ["grantInputBucket", "grantDynamoDb", "grantDynamoStreams", "grantBedrockInvoke"]
      attachOpenCvLayer  = true
      attachPopplerLayer = true
      timeout_seconds    = 60
    }
    bda_output_processor = {
      function_name      = "bda-output-processor"
      role_name          = "output-processor-role"
      handler            = "handlers.bda_output_processor"
      description        = "Processes BDA output and updates DynamoDB"
      policies           = ["grantOutputBucket", "grantDynamoDb"]
      attachOpenCvLayer  = false
      attachPopplerLayer = false
      timeout_seconds    = 60
    }
  } : {}


  # derive unique roles from lambda functions defined above
  lambda_roles = {
    for func_key, func_config in local.lambda_functions :
    func_config.role_name => func_config.role_name
  }
}

module "dde_input_bucket" {
  count        = local.document_data_extraction_config != null ? 1 : 0
  source       = "../../modules/storage"
  name         = "${local.prefix}${local.document_data_extraction_config.input_bucket_name}"
  is_temporary = local.is_temporary
}

module "dde_output_bucket" {
  count        = local.document_data_extraction_config != null ? 1 : 0
  source       = "../../modules/storage"
  name         = "${local.prefix}${local.document_data_extraction_config.output_bucket_name}"
  is_temporary = local.is_temporary
}

module "dde" {
  count  = local.document_data_extraction_config != null ? 1 : 0
  source = "../../modules/document-data-extraction/resources"

  standard_output_configuration = local.document_data_extraction_config.standard_output_configuration
  tags                          = local.tags

  blueprints_map = {
    for blueprint in fileset(local.document_data_extraction_config.blueprints_path, "*") :
    split(".", blueprint)[0] => {
      schema = file("${local.document_data_extraction_config.blueprints_path}/${blueprint}")
      type   = "DOCUMENT"
      tags   = local.tags
    }
  }

  name = "${local.prefix}${local.document_data_extraction_config.name}"

  data_access_policy_arns = {
    input_bucket  = module.dde_input_bucket[0].access_policy_arn,
    output_bucket = module.dde_output_bucket[0].access_policy_arn
  }
}

#-------------------
# Storage Resources
#-------------------
resource "aws_s3_bucket" "lambda_artifacts" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  bucket = "${local.prefix}documentai-lambda-artifacts"
}

resource "aws_dynamodb_table" "document_metadata" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  name           = "${local.prefix}${local.document_data_extraction_config.document_metadata_table_name}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "fileName"
  
  attribute {
    name = "fileName"
    type = "S"
  }
  
  attribute {
    name = "jobId"
    type = "S"
  }

  global_secondary_index {
    name            = "jobId-index"
    hash_key        = "jobId"
    projection_type = "ALL"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = local.tags
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
        "${aws_dynamodb_table.document_metadata[0].arn}/index/*"
      ]
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_policy" "dynamodb_streams" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  name = "${local.prefix}dynamodb-streams"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["dynamodb:DescribeStream", "dynamodb:GetRecords", "dynamodb:GetShardIterator", "dynamodb:ListStreams"]
      Resource = [
        aws_dynamodb_table.document_metadata[0].arn,
        "${aws_dynamodb_table.document_metadata[0].arn}/stream/*"
      ]
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_policy" "bedrock_invoke" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  name = "${local.prefix}bedrock-invoke"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "bedrock:InvokeDataAutomationAsync"
      Resource = [
        module.dde[0].bda_project_arn,
        local.document_data_extraction_environment_variables.DDE_PROFILE_ARN,
        "arn:aws:bedrock:us-east-2:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1",
        "arn:aws:bedrock:us-west-1:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1",
        "arn:aws:bedrock:us-west-2:${data.aws_caller_identity.current.account_id}:data-automation-profile/us.data-automation-v1"
      ]
      Effect = "Allow"
    }]
  })
}

#-------------------
# IAM Roles
#-------------------
resource "aws_iam_role" "lambda_roles" {
  for_each = local.lambda_roles
  
  name = "${local.prefix}${each.value}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

#-------------------
# Attach IAM Policies to Roles
#-------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  for_each = local.lambda_roles
  
  role       = aws_iam_role.lambda_roles[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# custom policies based on lambda definitions above
resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each = {
    for pair in flatten([
      for func_key, func_config in local.lambda_functions : [
        for policy in func_config.policies : {
          key = "${func_config.role_name}-${policy}"
          role_name = func_config.role_name
          policy_arn = (
            policy == "grantInputBucket" ? module.dde_input_bucket[0].access_policy_arn :
            policy == "grantOutputBucket" ? module.dde_output_bucket[0].access_policy_arn :
            policy == "grantDynamoDb" ? aws_iam_policy.dynamodb_read_write[0].arn :
            policy == "grantDynamoStreams" ? aws_iam_policy.dynamodb_streams[0].arn :
            policy == "grantBedrockInvoke" ? aws_iam_policy.bedrock_invoke[0].arn : null
          )
        }
      ]
    ]) : pair.key => pair
  }
  
  role       = aws_iam_role.lambda_roles[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

#-------------------
# Placeholder Lambda Code (will be replaced with actual app code during full app/infra deployment)
#-------------------
data "archive_file" "placeholder_lambda" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  type        = "zip"
  output_path = "/tmp/handlers.zip"
  source {
    content  = "def handler(event, context): pass"
    filename = "handler.py"
  }
}

resource "aws_s3_object" "lambda_code" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  bucket = aws_s3_bucket.lambda_artifacts[0].bucket
  key    = "handlers.zip"
  source = data.archive_file.placeholder_lambda[0].output_path
}

#-------------------
# Lambda Permissions for EventBridge
#-------------------
resource "aws_lambda_permission" "allow_eventbridge_ddb_insert" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions["ddb_insert_file_name"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.input_bucket_object_created[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_output_processor" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions["bda_output_processor"].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.output_bucket_object_created[0].arn
}


#-------------------
# Lambda Layers
#-------------------
data "external" "opencv_layer_build" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  program = ["bash", "-c", <<-EOT
    set -e
    cd "${path.module}/../layers/opencv"
    rm -rf output
    mkdir -p output/python
    docker run --rm --entrypoint="" -v $(pwd):/workspace -v $(pwd)/output:/asset-output \
      public.ecr.aws/lambda/python:3.11 \
      /bin/bash -c "pip install --no-cache-dir --platform manylinux2014_x86_64 --only-binary=:all: --implementation cp --python-version 311 -r /workspace/requirements.txt -t /asset-output/python" >&2
    cd output && zip -r opencv-layer.zip python/ >&2
    aws s3 cp opencv-layer.zip s3://${aws_s3_bucket.lambda_artifacts[0].bucket}/opencv-layer.zip >&2
    echo '{"status": "success"}'
  EOT
  ]
}


data "external" "poppler_layer_build" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  program = ["bash", "-c", <<-EOT
    set -e
    cd "${path.module}/../layers/poppler"
    docker build --platform linux/amd64 -t poppler-layer . >&2
    rm -rf output
    mkdir -p output
    docker run --rm -v $(pwd)/output:/output poppler-layer sh -c "cp -r /opt/. /output/" >&2
    cd output && zip -r poppler-layer.zip . >&2
    aws s3 cp poppler-layer.zip s3://${aws_s3_bucket.lambda_artifacts[0].bucket}/poppler-layer.zip >&2
    echo '{"status": "success"}'
  EOT
  ]
}

resource "aws_lambda_layer_version" "opencv_layer" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  layer_name          = "${local.prefix}opencv-numpy-pillow"
  description         = "OpenCV, NumPy, and Pillow libraries for image processing"
  compatible_runtimes = ["python3.11"]
  
  s3_bucket = aws_s3_bucket.lambda_artifacts[0].bucket
  s3_key    = "opencv-layer.zip"
  
  depends_on = [data.external.opencv_layer_build]
}

resource "aws_lambda_layer_version" "poppler_layer" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  layer_name               = "${local.prefix}poppler-utils"
  description              = "Poppler utilities for PDF processing"
  compatible_runtimes      = ["python3.11"]
  compatible_architectures = ["x86_64"]
  
  s3_bucket = aws_s3_bucket.lambda_artifacts[0].bucket
  s3_key    = "poppler-layer.zip"
  
  depends_on = [data.external.poppler_layer_build]
}

#-------------------
# Lambda Functions
#-------------------
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions
  
  s3_bucket     = aws_s3_bucket.lambda_artifacts[0].bucket
  s3_key        = "handlers.zip"
  function_name = "${local.prefix}${each.value.function_name}"
  role          = aws_iam_role.lambda_roles[each.value.role_name].arn
  handler       = each.value.handler
  runtime       = "python3.11"
  description   = each.value.description
  timeout       = each.value.timeout_seconds
  depends_on    = [ aws_s3_object.lambda_code ]

  # add layers as needed
  layers = compact([
    each.value.attachOpenCvLayer ? aws_lambda_layer_version.opencv_layer[0].arn : null,
    each.value.attachPopplerLayer ? aws_lambda_layer_version.poppler_layer[0].arn : null
  ])

  environment {
    variables = merge(
      local.document_data_extraction_environment_variables,
      each.value.attachPopplerLayer ? {
        PATH = "/opt/bin:/usr/local/bin:/usr/bin:/bin"
        LD_LIBRARY_PATH = "/opt/lib64:/lib64:/usr/lib64"
      } : {}
    )
  }
}


#-------------------
# Event Handlers
#-------------------
#------------------- Input Bucket Write -------------------
resource "aws_cloudwatch_event_rule" "input_bucket_object_created" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  name = "${local.prefix}input-bucket-object-created"
  event_pattern = jsonencode({
    detail-type = ["Object Created"]
    source      = ["aws.s3"]
    detail = {
      bucket = {
        name = ["${local.prefix}${local.document_data_extraction_config.input_bucket_name}"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "ddb_insert_file_name_target" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.input_bucket_object_created[0].name
  target_id = "DdbInsertFileName"
  arn       = aws_lambda_function.functions["ddb_insert_file_name"].arn
}

#------------------- DynamoDB Write -------------------
resource "aws_lambda_event_source_mapping" "bda_invoker_target" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  event_source_arn  = aws_dynamodb_table.document_metadata[0].stream_arn
  function_name     = aws_lambda_function.functions["bda_invoker"].arn
  starting_position = "LATEST"
  batch_size        = 1
  
  filter_criteria {
    filter {
      pattern = jsonencode({
        dynamodb = {
          NewImage = {
            processStatus = {
              S = ["not_started"]
            }
          }
        }
      })
    }
  }
}

#------------------- BDA Output Bucket Write -------------------
resource "aws_cloudwatch_event_rule" "output_bucket_object_created" {
  count = local.document_data_extraction_config != null ? 1 : 0
  
  name = "${local.prefix}output-bucket-object-created"
  event_pattern = jsonencode({
    detail-type = ["Object Created"]
    source      = ["aws.s3"]
    detail = {
      bucket = {
        name = ["${local.prefix}${local.document_data_extraction_config.output_bucket_name}"]
      }
      object = {
        key = [{
          suffix = "job_metadata.json"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "bda_output_processor_target" {
  count = local.document_data_extraction_config != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.output_bucket_object_created[0].name
  target_id = "BdaOutputProcessor"
  arn       = aws_lambda_function.functions["bda_output_processor"].arn
}