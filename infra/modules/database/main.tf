data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  master_username       = "postgres"
  primary_instance_name = "${var.name}-primary"
  role_checker_package  = "${path.root}/role_checker.zip"
}


#------------------------#
# Database Configuration #
#------------------------#

resource "aws_rds_cluster" "db" {
  # checkov:skip=CKV2_AWS_27:have concerns about sensitive data in logs; want better way to get this information
  # checkov:skip=CKV2_AWS_8:TODO add backup selection plan using tags

  # cluster identifier is a unique identifier within the AWS account
  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.CreateInstance.html
  cluster_identifier = var.name

  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  database_name     = var.database_name
  master_username   = local.master_username
  master_password   = aws_ssm_parameter.random_db_password.value
  storage_encrypted = true
  # checkov:skip=CKV_AWS_128:Auth decision needs to be ironed out
  # checkov:skip=CKV_AWS_162:Auth decision needs to be ironed out
  # iam_database_authentication_enabled = true
  deletion_protection = true
  # final_snapshot_identifier = "${var.name}-final"
  skip_final_snapshot = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_rds_cluster_instance" "primary" {
  identifier                 = local.primary_instance_name
  cluster_identifier         = aws_rds_cluster.db.id
  instance_class             = "db.serverless"
  engine                     = aws_rds_cluster.db.engine
  engine_version             = aws_rds_cluster.db.engine_version
  auto_minor_version_upgrade = true
  monitoring_role_arn        = aws_iam_role.rds_enhanced_monitoring.arn
  monitoring_interval        = 30
}

resource "random_password" "random_db_password" {
  length = 48
  # Remove '@' sign from allowed characters since only printable ASCII characters besides '/', '@', '"', ' ' may be used.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "random_db_password" {
  name  = "/db/${var.name}/master-password"
  type  = "SecureString"
  value = random_password.random_db_password.result
}

#----------------#
# Network Access #
#----------------#

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db"
  description = "Inbound traffic rules for the database layer"
  vpc_id      = var.vpc_id

  ingress {
    security_groups = var.ingress_security_group_ids
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }
}

#----------------#
# Authentication #
#----------------#

# data "aws_iam_policy_document" "app_db_access" {
#   # Policy to allow connection to RDS via IAM database authentication as pfml_api user
#   # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html
#   statement {
#     actions = [
#       "rds-db:connect"
#     ]

#     resources = [
#       "${local.iam_db_user_arn_prefix}/app"
#     ]
#   }
# }

# resource "aws_iam_policy" "db_user_pfml_api" {
#   name   = "${local.app_name}-${var.environment_name}-db_user_pfml_api-policy"
#   policy = data.aws_iam_policy_document.db_user_pfml_api.json
# }

#------------------#
# Database Backups #
#------------------#

# Backup plan that defines when and how to backup and which backup vault to store backups in
# See https://docs.aws.amazon.com/aws-backup/latest/devguide/about-backup-plans.html
resource "aws_backup_plan" "backup_plan" {
  name = "${var.name}-db-backup-plan"

  rule {
    rule_name         = "${var.name}-db-backup-rule"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = "cron(0 7 ? * SUN *)" # Run Sundays at 12pm (EST)
  }
}

# Backup vault that stores and organizes backups
# See https://docs.aws.amazon.com/aws-backup/latest/devguide/vaults.html
resource "aws_backup_vault" "backup_vault" {
  name        = "${var.name}-db-backup-vault"
  kms_key_arn = data.aws_kms_key.backup_vault_key.arn
}

# KMS Key for the vault
# This key was created by AWS by default alongside the vault
data "aws_kms_key" "backup_vault_key" {
  key_id = "alias/aws/backup"
}

# Backup selection defines which resources to backup
# See https://docs.aws.amazon.com/aws-backup/latest/devguide/assigning-resources.html
# and https://docs.aws.amazon.com/aws-backup/latest/devguide/API_BackupSelection.html
resource "aws_backup_selection" "db_backup" {
  name         = "${var.name}-db-backup"
  plan_id      = aws_backup_plan.backup_plan.id
  iam_role_arn = aws_iam_role.db_backup_role.arn

  resources = [
    aws_rds_cluster.db.arn
  ]
}

# Role that AWS Backup uses to authenticate when backing up the target resource
resource "aws_iam_role" "db_backup_role" {
  name_prefix        = "${var.name}-db-backup-role-"
  assume_role_policy = data.aws_iam_policy_document.db_backup_policy.json
}

data "aws_iam_policy_document" "db_backup_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "db_backup_role_policy_attachment" {
  role       = aws_iam_role.db_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

#----------------------------------#
# IAM role for enhanced monitoring #
#----------------------------------#

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "aurora-enhanced-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

#---------------#
# Query Logging #
#---------------#

resource "aws_rds_cluster_parameter_group" "rds_query_logging" {
  name        = var.name
  family      = "aurora-postgresql13"
  description = "Default cluster parameter group"

  parameter {
    name = "log_statement"
    # Logs data definition statements (e.g. DROP, ALTER, CREATE)
    value = "ddl"
  }

  parameter {
    name = "log_min_duration_statement"
    # Logs all statements that run 100ms or longer
    value = "100"
  }
}

#-------------------------------------------#
# Database Role Provisioner Lambda Function #
#-------------------------------------------#

resource "aws_lambda_function" "db_role_provisioner" {
  function_name = "${var.name}-db-role-provisioner"

  s3_bucket = aws_s3_bucket.db_role_provisioner_bucket.id
  s3_key    = aws_s3_object.db_role_provisioner.key

  runtime = "python3.9"
  handler = "role_provisioner.lambda_handler"

  source_code_hash = data.archive_file.db_role_provisioner.output_base64sha256

  role = aws_iam_role.db_role_provisioner_lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "db_role_provisioner" {
  name = "/aws/lambda/${aws_lambda_function.db_role_provisioner.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "db_role_provisioner_lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.db_role_provisioner_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "db_role_provisioner" {
  type = "zip"

  source_dir  = "${path.module}/role_provisioner"
  output_path = "${path.root}/role_provisioner.zip"
}

resource "aws_s3_object" "db_role_provisioner" {
  bucket = aws_s3_bucket.db_role_provisioner_bucket.id

  key    = "role_provisioner.zip"
  source = data.archive_file.db_role_provisioner.output_path

  etag = filemd5(data.archive_file.db_role_provisioner.output_path)
}

resource "aws_s3_bucket" "db_role_provisioner_bucket" {
  bucket = "${var.name}-db-role-provisioner"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.db_role_provisioner_bucket.id
  acl    = "private"
}

#------------------#
# Database Checker #
#------------------#

data "aws_iam_policy_document" "role_checker_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role_checker" {
  name               = "${var.name}-checker"
  assume_role_policy = data.aws_iam_policy_document.role_checker_assume_role.json
}

data "archive_file" "role_checker" {
  type        = "zip"
  source_dir  = "${path.module}/role_checker"
  output_path = local.role_checker_package
}

resource "aws_lambda_function" "role_checker" {
  function_name = "${var.name}-role-checker"

  filename         = local.role_checker_package
  source_code_hash = data.archive_file.role_checker.output_base64sha256
  runtime          = "python3.9"
  handler          = "role_checker.lambda_handler"
  role             = aws_iam_role.role_checker.arn
}
