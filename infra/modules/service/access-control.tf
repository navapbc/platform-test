#----------------
# Access Control
#----------------

resource "aws_iam_role" "task_executor" {
  name               = local.task_executor_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
}

resource "aws_iam_role" "app_service" {
  name               = "${var.service_name}-app"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
}

resource "aws_iam_role" "migrator_task" {
  count = var.db_vars != null ? 1 : 0

  name               = "${var.service_name}-migrator"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_tasks_assume_role_policy" {
  statement {
    sid = "ECSTasksAssumeRole"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "states.amazonaws.com",
        "scheduler.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "task_executor" {
  # Allow ECS to log to Cloudwatch.
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["${aws_cloudwatch_log_group.service_logs.arn}:*"]
  }

  # Allow ECS to authenticate with ECR
  statement {
    sid = "ECRAuth"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  # Allow ECS to download images.
  statement {
    sid = "ECRPullAccess"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [data.aws_ecr_repository.app.arn]
  }

  dynamic "statement" {
    for_each = length(var.secrets) > 0 ? [1] : []
    content {
      sid       = "SecretsAccess"
      actions   = ["ssm:GetParameters"]
      resources = [for secret in var.secrets : secret.valueFrom]
    }
  }
}

data "aws_iam_policy_document" "pass_role" {
  statement {
    sid = "PassRole"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.app_service.arn,
      aws_iam_role.task_executor.arn,
    ]
  }
}

resource "aws_iam_policy" "pass_role" {
  name   = "${var.service_name}-pass-role-policy"
  policy = data.aws_iam_policy_document.pass_role.json
}

resource "aws_iam_role_policy" "task_executor" {
  name   = "${var.service_name}-task-executor-role-policy"
  role   = aws_iam_role.task_executor.id
  policy = data.aws_iam_policy_document.task_executor.json
}

resource "aws_iam_role_policy_attachment" "pass_role" {
  role       = aws_iam_role.app_service.name
  policy_arn = aws_iam_policy.pass_role.arn
}

resource "aws_iam_role_policy_attachment" "extra_policies" {
  for_each = var.extra_policies

  role       = aws_iam_role.app_service.name
  policy_arn = each.value
}
