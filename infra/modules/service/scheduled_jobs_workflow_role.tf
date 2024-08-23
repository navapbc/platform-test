resource "aws_iam_role" "scheduled_jobs_workflow_role" {
  name               = "${var.service_name}-scheduled-jobs-workflow"
  assume_role_policy = data.aws_iam_policy_document.scheduled_jobs_workflow_assume_role_policy.json
}

resource "aws_iam_policy" "scheduled_jobs_workflow_policy" {
  name   = "${var.service_name}-scheduled-jobs-workflow"
  policy = data.aws_iam_policy_document.scheduled_jobs_workflow_policy.json
}

data "aws_iam_policy_document" "scheduled_jobs_workflow_assume_role_policy" {
  statement {
    sid = "ECSTasksAssumeRole"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "states.amazonaws.com",
      ]
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "scheduled_jobs_workflow_policy" {
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
    resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"]
  }

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/ecs-iam.html
  statement {
    sid = "StepFunctionsRunTask"
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = ["*"]
  }
}
