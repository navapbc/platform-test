#--------------------------------
# Scheduler Workflow Manager Role
#--------------------------------
# This role and policy are used by the Step Functions state machine that manages the scheduled jobs workflow.

resource "aws_iam_role" "workflow_orchestrator" {
  name                = "${var.service_name}-workflow-orchestrator"
  managed_policy_arns = [aws_iam_policy.orchestrate_workflows.arn]
  assume_role_policy  = data.aws_iam_policy_document.workflow_orchestrator_assume_role.json
}

# policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/procedure-create-iam-role.html
data "aws_iam_policy_document" "workflow_orchestrator_assume_role" {
  statement {
    sid     = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_iam_policy" "orchestrate_workflows" {
  name   = "${var.service_name}-workflow-orchestrator"
  policy = data.aws_iam_policy_document.orchestrate_workflows.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "orchestrate_workflows" {
  # checkov:skip=CKV_AWS_111:These permissions are scoped just fine

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html
  statement {
    sid = "UnscopeLogsPermissions"
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogStream",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/ecs-iam.html
  statement {
    sid = "StepFunctionsEvents"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["${aws_ecs_task_definition.app.arn_without_revision}:*"]
    condition {
      test     = "ArnLike"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.cluster.arn]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${var.service_name}/*"]
    condition {
      test     = "ArnLike"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.cluster.arn]
    }
  }


  statement {
    sid = "PassRole"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.task_executor.arn,
      aws_iam_role.app_service.arn,
    ]
  }
}
