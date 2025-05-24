# Allow direct SES access for sending email on behalf of this email identity.
resource "aws_sesv2_email_identity_policy" "sender" {
  email_identity = aws_sesv2_email_identity.sender_domain.email_identity
  policy_name    = "EmailSending"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "AllowSESAccess",
          Effect = "Allow",
          Principal = {
            AWS = data.aws_caller_identity.current.account_id
          },
          Action   = "ses:*",
          Resource = aws_sesv2_email_identity.sender_domain.arn,
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            }
          }
        }
      ]
    }
  )
}

resource "aws_iam_policy" "ses_access" {
  name        = "${local.dash_domain}-ses-access"
  description = "Policy for sending emails using SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = [
          aws_sesv2_email_identity.sender_domain.arn,
          "arn:*:ses:*:*:configuration-set/*",
        ]
      }
    ]
  })
}
