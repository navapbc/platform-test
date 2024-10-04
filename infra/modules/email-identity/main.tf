# This module manages an SESv2 email identity.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Construct DNS records to be added to the sending domain.
  # Only used if the sender identity verification method is domain verification.
  dkim_dns_verification_records = var.email_verification_method == "domain" ? [
    for token in data.aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens : {
      type   = "CNAME"
      name   = "${token}._domainkey"
      record = "${token}.dkim.amazonses.com"
    }
  ] : []
}

# Verify email sender identity.
# Docs: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-email-manage-verify.html
resource "aws_sesv2_email_identity" "sender" {
  email_identity         = var.email_verification_method == "email" ? var.sender_email : var.sender_email_domain_name
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

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "PinpointEmail",
      "Effect": "Allow",
      "Principal":{
        "Service": "pinpoint.amazonaws.com"
      },
      "Action": "ses:*",
      "Resource": "${aws_sesv2_email_identity.sender.arn}",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "StringLike": {
          "aws:SourceArn": "arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/*"
        }
      }
    }
  ]
}
EOF
}

# If email_verification_method is "domain", create a Route53 hosted zone for the sending
# domain.
resource "aws_route53_zone" "zone" {
  count = var.email_verification_method == "domain" ? 1 : 0
  name  = var.sender_email_domain_name
  # checkov:skip=CKV2_AWS_38:TODO(https://github.com/navapbc/template-infra/issues/560) enable DNSSEC
}

# DNS records for email identity verification if email_verification_method is "domain"
resource "aws_route53_record" "verification" {
  for_each = local.dkim_dns_verification_records

  allow_overwrite = true
  zone_id         = aws_route53_zone.zone[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}
