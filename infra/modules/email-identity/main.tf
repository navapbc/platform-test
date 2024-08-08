# This module manages an SESv2 email identity.
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity
locals {
  # Extract the domain used for sender identity verification from the sender_email.
  domain = regex("@(.*)", var.sender_email)[0]

  # Construct DNS records to be added to the sending domain.
  # Only used if the sender identity verification method is domain verification.
  dkim_dns_verification_records = var.email_verification_method == "domain" ? [
    for token in aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens : {
      type  = "CNAME"
      name  = "${token}._domainkey"
      value = "${token}.dkim.amazonses.com"
    }
  ] : []
}

# Verify email sender identity.
# Docs: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-email-manage-verify.html
resource "aws_sesv2_email_identity" "sender" {
  email_identity         = var.email_verification_method == "email" ? var.sender_email : local.domain
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
