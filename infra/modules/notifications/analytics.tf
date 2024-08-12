# IAM role used by AWS Pinpoint to submit events to Mobile Analytics' event ingestion service.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "analytics" {
  name               = "${var.name}-notifications-analytics"
  assume_role_policy = data.aws_iam_policy_document.analytics_assume_role_policy.json
}

data "aws_iam_policy_document" "analytics_assume_role_policy" {
  statement {
    sid = "MobileAnalyticsAssumeRole"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["pinpoint.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "analytics_access_policy" {
  name        = "${var.name}-analytics-access"
  description = "Allow ${var.name}-analytics-access to access Mobile Analytics"
  policy      = data.aws_iam_policy_document.analytics_access_policy.json
}

data "aws_iam_policy_document" "analytics_access_policy" {
  statement {
    sid    = "MobileAnalyticsAccess"
    effect = "Allow"
    actions = [
      "mobiletargeting:PutEvents",
    ]
    resources = [
      "arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/${aws_pinpoint_app.app.application_id}",
      "arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/${aws_pinpoint_app.app.application_id}/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "analytics_access_policy" {
  role       = aws_iam_role.analytics.name
  policy_arn = aws_iam_policy.analytics_access_policy.arn
}
