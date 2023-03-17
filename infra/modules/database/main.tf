data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  master_username = "postgres"
}


############################
## Database Configuration ##
############################

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
}

resource "aws_rds_cluster_instance" "primary" {
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

################################################################################
# Backup Configuration
################################################################################

resource "aws_backup_plan" "postgresql" {
  name = "${var.name}-backup-plan"

  rule {
    rule_name         = "${var.name}-backup-rule"
    target_vault_name = aws_backup_vault.postgresql.name
    schedule          = "cron(0 7 ? * SUN *)" # Run Sundays at 12pm (EST)
  }
}

# backup selection
resource "aws_backup_selection" "postgresql_backup" {
  iam_role_arn = aws_iam_role.postgresql_backup.arn
  name         = "${var.name}-backup"
  plan_id      = aws_backup_plan.postgresql.id

  resources = [
    aws_rds_cluster.db.arn
  ]
}

# KMS Key for the vault
# This key was created by AWS by default alongside the vault
data "aws_kms_key" "postgresql" {
  key_id = "alias/aws/backup"
}

# create backup vault
resource "aws_backup_vault" "postgresql" {
  name        = "${var.name}-vault"
  kms_key_arn = data.aws_kms_key.postgresql.arn
}

# create IAM role
resource "aws_iam_role" "postgresql_backup" {
  name_prefix        = "aurora-backup-"
  assume_role_policy = data.aws_iam_policy_document.postgresql_backup.json
}

resource "aws_iam_role_policy_attachment" "postgresql_backup" {
  role       = aws_iam_role.postgresql_backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

data "aws_iam_policy_document" "postgresql_backup" {
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

################################################################################
# IAM role for enhanced monitoring
################################################################################

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

################################################################################
# Parameters for Query Logging
################################################################################

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
