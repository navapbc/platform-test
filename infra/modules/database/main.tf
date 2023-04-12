data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  master_username       = "postgres"
  app_username          = "app"
  migrator_username     = "migrator"
  schema_name           = "app"
  primary_instance_name = "${var.name}-primary"
  role_manager_package  = "${path.root}/role_manager.zip"

  # The ARN that represents the users accessing the database are of the format: "arn:aws:rds-db:<region>:<account-id>:dbuser:<resource-id>/<database-user-name>""
  # See https://aws.amazon.com/blogs/database/using-iam-authentication-to-connect-with-pgadmin-amazon-aurora-postgresql-or-amazon-rds-for-postgresql/
  db_user_arn_prefix = "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster_instance.primary.dbi_resource_id}"
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
  port              = var.port
  master_username   = local.master_username
  master_password   = aws_ssm_parameter.random_db_password.value
  storage_encrypted = true
  # checkov:skip=CKV_AWS_128:Auth decision needs to be ironed out
  # checkov:skip=CKV_AWS_162:Auth decision needs to be ironed out
  iam_database_authentication_enabled = true
  deletion_protection                 = true
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
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
  }
}

#----------------#
# Authentication #
#----------------#

resource "aws_iam_policy" "db_access" {
  name   = "${var.name}-db-access"
  policy = data.aws_iam_policy_document.db_access.json
}

data "aws_iam_policy_document" "db_access" {
  # Policy to allow connection to RDS via IAM database authentication as pfml_api user
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html
  statement {
    actions = [
      "rds-db:connect"
    ]

    resources = [
      "${local.db_user_arn_prefix}/${local.app_username}",
      "${local.db_user_arn_prefix}/${local.migrator_username}",
    ]
  }
}

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

#-----------------------------------------------------------------------------#
# Role Manager Lambda Function                                                #
#                                                                             #
# Resources for the lambda function that is used for managing database roles  #
# This includes creating and granting permissions to roles                    #
# as well as viewing existing roles                                           #
#-----------------------------------------------------------------------------#

resource "aws_lambda_function" "role_manager" {
  function_name = "${var.name}-role-manager"

  filename         = local.role_manager_package
  source_code_hash = data.archive_file.role_manager.output_base64sha256
  runtime          = "python3.9"
  handler          = "role_manager.lambda_handler"
  role             = aws_iam_role.role_manager.arn

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.ingress_security_group_ids
  }

  environment {
    variables = {
      DB_HOST       = aws_rds_cluster.db.endpoint
      DB_PORT       = aws_rds_cluster.db.port
      DB_USER       = local.master_username
      DB_PASSWORD   = aws_ssm_parameter.random_db_password.value
      SCHEMA_NAME   = local.schema_name
      APP_USER      = local.app_username
      MIGRATOR_USER = local.migrator_username
    }
  }
}

data "archive_file" "role_manager" {
  type        = "zip"
  source_dir  = "${path.module}/role_manager"
  output_path = local.role_manager_package
}

resource "aws_iam_role" "role_manager" {
  name                = "${var.name}-manager"
  assume_role_policy  = data.aws_iam_policy_document.role_manager_assume_role.json
  managed_policy_arns = [data.aws_iam_policy.lambda_vpc_access.arn]
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