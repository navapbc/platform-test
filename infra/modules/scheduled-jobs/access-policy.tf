resource "aws_iam_policy" "access_policy" {
  name   = "${var.service_name}-scheduled-jobs-access"
  policy = data.aws_iam_policy_document.access_policy.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "access_policy" {
  # via https://docs.aws.amazon.com/step-functions/latest/dg/cw-logs.html
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

  statement {
    sid = "StepFunctionsRunTask"
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:DescribeTasks",
    ]
    resources = ["*"]
  }

  # statement {
  #   sid = "PassRole"
  #   actions = [
  #     "iam:PassRole",
  #   ]
  #   resources = [
  #     aws_iam_role.app_service.arn,
  #     aws_iam_role.task_executor.arn,
  #   ]
  # }

  statement {
    sid = "StepFunctionsEvents"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = ["*"]
  }

  statement {
    sid = "StepFunctionsStartExecution"
    actions = [
      "states:StartExecution",
    ]
    resources = ["arn:aws:states:*:*:stateMachine:*"]
  }
}
