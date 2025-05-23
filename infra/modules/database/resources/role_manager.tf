# Role Manager Lambda Function
# ----------------------------
#
# Resources for the lambda function that is used for managing database roles
# This includes creating and granting permissions to roles
# as well as viewing existing roles

locals {
  db_password_param_name    = "/aws/reference/secretsmanager/${data.aws_secretsmanager_secret.db_password.name}"
  role_manager_archive_path = "${path.module}/role_manager.zip"
}

resource "aws_lambda_function" "role_manager" {
  function_name = local.role_manager_name

  filename         = local.role_manager_archive_path
  source_code_hash = filebase64sha256(local.role_manager_archive_path)
  runtime          = "python3.9"
  handler          = "role_manager.lambda_handler"
  role             = aws_iam_role.role_manager.arn
  kms_key_arn      = aws_kms_key.role_manager.arn

  reserved_concurrent_executions = 1

  vpc_config {
    subnet_ids         = module.network.database_subnet_ids
    security_group_ids = [aws_security_group.role_manager.id]
  }

  environment {
    variables = {
      DB_HOST                = aws_rds_cluster.db.endpoint
      DB_PORT                = aws_rds_cluster.db.port
      DB_USER                = local.master_username
      DB_NAME                = aws_rds_cluster.db.database_name
      DB_PASSWORD_PARAM_NAME = local.db_password_param_name
      DB_PASSWORD_SECRET_ARN = aws_rds_cluster.db.master_user_secret[0].secret_arn
      DB_SCHEMA              = module.interface.schema_name
      APP_USER               = module.interface.app_username
      MIGRATOR_USER          = module.interface.migrator_username
      PYTHONPATH             = "vendor"
    }
  }

  # Ensure AWS Lambda functions with tracing are enabled
  # https://docs.bridgecrew.io/docs/bc_aws_serverless_4
  tracing_config {
    mode = "Active"
  }
  timeout = 30
  # checkov:skip=CKV_AWS_272:TODO(https://github.com/navapbc/template-infra/issues/283)

  # checkov:skip=CKV_AWS_116:Dead letter queue (DLQ) configuration is only relevant for asynchronous invocations
}

data "aws_kms_key" "default_ssm_key" {
  key_id = "alias/aws/ssm"
}

# KMS key used to encrypt role manager's environment variables
resource "aws_kms_key" "role_manager" {
  description         = "Key for Lambda function ${local.role_manager_name}"
  enable_key_rotation = true
}

data "aws_secretsmanager_secret" "db_password" {
  # master_user_secret is available when aws_rds_cluster.db.manage_master_user_password
  # is true (see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster#master_user_secret)
  arn = aws_rds_cluster.db.master_user_secret[0].secret_arn
}

# IAM for Role Manager lambda function
resource "aws_iam_role" "role_manager" {
  name               = "${var.name}-manager"
  assume_role_policy = data.aws_iam_policy_document.role_manager_assume_role.json
}

resource "aws_iam_role_policy_attachment" "role_manager_vpc_access" {
  role       = aws_iam_role.role_manager.name
  policy_arn = data.aws_iam_policy.lambda_vpc_access.arn
}

resource "aws_iam_role_policy_attachment" "role_manager_app_db_access" {
  # Grants the role manager access to the DB as app and migrator users
  # so that it can performance database checks. This is needed by
  # the infra database tests
  role       = aws_iam_role.role_manager.name
  policy_arn = aws_iam_policy.app_db_access.arn
}

resource "aws_iam_role_policy_attachment" "role_manager_migrator_db_access" {
  # Grants the role manager access to the DB as app and migrator users
  # so that it can performance database checks. This is needed by
  # the infra database tests
  role       = aws_iam_role.role_manager.name
  policy_arn = aws_iam_policy.migrator_db_access.arn
}

resource "aws_iam_role_policy" "role_manager_access_to_db_password" {
  name = "${var.name}-role-manager-ssm-access"
  role = aws_iam_role.role_manager.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [data.aws_kms_key.default_ssm_key.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [data.aws_secretsmanager_secret.db_password.arn]
      },
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:parameter${local.db_password_param_name}"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "role_manager_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# AWS managed policy required by Lambda functions in order to access VPC resources
# see https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html
data "aws_iam_policy" "lambda_vpc_access" {
  name = "AWSLambdaVPCAccessExecutionRole"
}
