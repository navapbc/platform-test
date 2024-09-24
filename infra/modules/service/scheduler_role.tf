#----------------------
# Schedule Manager Role
#----------------------
# This role and policy are used by EventBridge to manage the scheduled jobs.

resource "aws_iam_role" "scheduler" {
  name                = "${var.service_name}-scheduler"
  managed_policy_arns = [aws_iam_policy.scheduler.arn]
  assume_role_policy  = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "scheduler" {
  name   = "${var.service_name}-scheduler"
  policy = data.aws_iam_policy_document.scheduler.json
}

data "aws_iam_policy_document" "scheduler" {

  statement {
    sid = "StepFunctionsEvents"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule"]
  }

  statement {
    sid = "StepFunctionsExecution"
    actions = [
      "states:StartExecution",
    ]
    resources = [for job in keys(var.scheduled_jobs) : "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.service_name}-${job}"]
  }

  statement {
    sid = "StepFunctionsDescribeStop"
    actions = [
      "states:DescribeExecution",
      "states:StopExecution",
    ]
    resources = [for job in keys(var.scheduled_jobs) : "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.service_name}-${job}:*"]
  }
}
