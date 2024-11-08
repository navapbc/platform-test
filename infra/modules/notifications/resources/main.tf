# This module manages an SESv2 email identity.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  mail_from_domain          = "mail.${var.domain_name}"
  stripped_domain_name      = replace(var.domain_name, "/[.]$/", "")
  stripped_mail_from_domain = replace(local.mail_from_domain, "/[.]$/", "")
  dash_domain               = replace(var.domain_name, ".", "-")
}

# Verify email sender identity.
# Docs: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-email-manage-verify.html
resource "aws_sesv2_email_identity" "sender" {
  email_identity         = local.dash_domain
  configuration_set_name = aws_sesv2_configuration_set.email.configuration_set_name
}

# The configuration set applied to messages that is sent through this email channel.
resource "aws_sesv2_configuration_set" "email" {
  configuration_set_name = var.name

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }
}

# Allow AWS Pinpoint to send email on behalf of this email identity.
# Docs: https://docs.aws.amazon.com/pinpoint/latest/developerguide/security_iam_id-based-policy-examples.html#security_iam_resource-based-policy-examples-access-ses-identities
resource "aws_sesv2_email_identity_policy" "sender" {
  email_identity = aws_sesv2_email_identity.sender.email_identity
  policy_name    = "PinpointEmail"

  policy = jsonencode(
    {
      Version = "2008-10-17",
      Statement = [
        {
          Sid    = "PinpointEmail",
          Effect = "Allow",
          Principal = {
            Service = "pinpoint.amazonaws.com"
          },
          Action   = "ses:*",
          Resource = "${aws_sesv2_email_identity.sender.arn}",
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
            },
            StringLike = {
              "aws:SourceArn" = "arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/*"
            }
          }
        }
      ]
    }
  )
}

resource "aws_sesv2_email_identity_mail_from_attributes" "sender" {
  email_identity   = aws_sesv2_email_identity.sender.email_identity
  mail_from_domain = local.stripped_mail_from_domain

  depends_on = [aws_sesv2_email_identity.sender]
}
