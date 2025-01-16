resource "aws_iam_policy" "access" {
  name        = "${var.name}-notifications-access"
  description = "Policy for calling SendMessages and SendUsersMessages on Pinpoint app ${var.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mobiletargeting:SendMessages",
          "mobiletargeting:SendUsersMessages"
        ]
        Resource = "${aws_pinpoint_app.app.arn}/messages"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = [
          var.domain_identity_arn,
          "arn:*:ses:*:*:configuration-set/*",
        ]
      }
    ]
  })
}
