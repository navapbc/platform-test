#----------------------
# Schedule Manager Role
#----------------------
# This role and policy are used by EventBridge to manage the scheduled jobs.

resource "aws_iam_role" "scheduler" {
  name                = "${var.service_name}-scheduler"
  managed_policy_arns = [aws_iam_policy.scheduled_jobs.arn]
  assume_role_policy  = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    sid     = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "scheduled_jobs" {
  name   = "${var.service_name}-scheduler"
  policy = data.aws_iam_policy_document.scheduled_jobs.json
}

data "aws_iam_policy_document" "scheduled_jobs" {

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/stepfunctions-iam.html
  statement {
    sid = "StepFunctionsEvents"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"]
  }

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/stepfunctions-iam.html
  dynamic "statement" {
    for_each = aws_sfn_state_machine.scheduled_jobs

    content {
      actions = [
        "states:StartExecution",
      ]
      resources = [statement.value.arn]
    }
  }

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/stepfunctions-iam.html
  dynamic "statement" {
    for_each = aws_sfn_state_machine.scheduled_jobs

    content {
      actions = [
        "states:DescribeExecution",
        "states:StopExecution",
      ]
      resources = ["${statement.value.arn}:*"]
    }
  }
}
