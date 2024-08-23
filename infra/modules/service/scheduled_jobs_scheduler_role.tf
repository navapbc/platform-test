resource "aws_iam_role" "scheduled_jobs_scheduler_role" {
  name               = "${var.service_name}-scheduled-jobs-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduled_jobs_scheduler_assume_role_policy.json
}

resource "aws_iam_policy" "scheduled_jobs_scheduler_policy" {
  name   = "${var.service_name}-scheduled-jobs-scheduler"
  policy = data.aws_iam_policy_document.scheduled_jobs_scheduler_policy.json
}

data "aws_iam_policy_document" "scheduled_jobs_scheduler_assume_role_policy" {
  statement {
    sid = "ECSTasksAssumeRole"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "scheduler.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "scheduled_jobs_scheduler_policy" {

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
    for_each = aws_sfn_state_machine.scheduled_job

    content {
      actions = [
        "states:StartExecution",
      ]
      resources = [statement.value.arn]
    }
  }

  # policy sourced via: https://docs.aws.amazon.com/step-functions/latest/dg/stepfunctions-iam.html
  dynamic "statement" {
    for_each = aws_sfn_state_machine.scheduled_job

    content {
      actions = [
        "states:DescribeExecution",
        "states:StopExecution",
      ]
      resources = ["${statement.value.arn}:*"]
    }
  }
}
