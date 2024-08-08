locals {
  # Extract the domain used for sender identity verification from the sender_email.
  domain = regex("@(.*)", var.sender_email)[0]

  # Construct DNS records to be added to the sending domain.
  # Only used if the sender identity verification method is domain verification.
  dkim_dns_verification_records = var.email_verification_method == "domain" ? [
    for token in flatten(aws_sesv2_email_identity.sender[*].dkim_signing_attributes.tokens) : {
      type  = "CNAME"
      name  = "${token}._domainkey"
      value = "${token}.dkim.amazonses.com"
    }
  ] : []
}

# The AWS Pinpoint Email channel requires sender identity verification. It supports:
# 1. email address verification: Verify an email address. An email is sent to the email
#    address with a link to verify you own the email address.
# 2. domain verification: Verify an entire domain. When you verify a new domain, AWS
#    provides a set of DNS records. You have to add these records to the DNS configuration
#    of the domain.
resource "aws_pinpoint_email_channel" "email" {
  application_id    = aws_pinpoint_app.app.application_id
  configuration_set = aws_sesv2_configuration_set.email.configuration_set_name
  from_address      = var.sender_email != null ? (var.sender_display_name != null ? "${var.sender_display_name} <${var.sender_email}>" : var.sender_email) : null
  identity          = aws_sesv2_email_identity.sender.arn

  # Note: There is a known bug where role_arn isn't being persisted to AWS. This means
  # that this module will always show that there are changes that haven't been applied.
  # Commenting it out for now.
  # See https://github.com/hashicorp/terraform-provider-aws/issues/38772
  # role_arn          = aws_iam_role.analytics.arn
}

# The configuration set applied to messages that sent through this email channel.
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

# Handles sender identity verification.
resource "aws_sesv2_email_identity" "sender" {
  email_identity         = var.email_verification_method == "email" ? var.sender_email : local.domain
  configuration_set_name = aws_sesv2_configuration_set.email.configuration_set_name
}
