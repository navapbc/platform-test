resource "aws_iam_policy" "access" {
  name        = "pinpoint_policy"
  description = "Policy for calling SendMessages and SendUsersMessages on Pinpoint app"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mobiletargeting:SendMessages",
          "mobiletargeting:SendUsersMessages"
        ]
        Resource = aws_pinpoint_app.app.arn
      }
    ]
  })
}
