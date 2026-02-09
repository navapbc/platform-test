data "aws_caller_identity" "current" {}

resource "aws_iam_role" "logging_role" {
  name = "sms-logging-role-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sms-voice.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sms_logging_permissions" {
  name = "sms-logging-policy-${var.name}"
  role = aws_iam_role.logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.sms_logs.arn,
          "${aws_cloudwatch_log_group.sms_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "sms_access" {
  name        = "${var.name}-end-user-messaging-sms-access"
  description = "Policy for sending SMS via AWS End User Messaging for ${var.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sms-voice:SendTextMessage",
          "sms-voice:DescribePhoneNumbers",
          "sms-voice:DescribePools",
          "sms-voice:DescribeConfigurationSets",
          "sms-voice:DescribeOptOutLists"
        ]
        Resource = "*"
      }
    ]
  })
}