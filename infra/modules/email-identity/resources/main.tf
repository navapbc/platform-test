# This module manages an SESv2 email identity.
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity

# Retrieve shared config names.
module "interface" {
  source = "../interface"

  sender_email = var.sender_email
}

# Verify email sender identity.
# Docs: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-email-manage-verify.html
resource "aws_sesv2_email_identity" "sender" {
  email_identity         = var.email_verification_method == "email" ? var.sender_email : module.interface.domain
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

# Use the data module to handle all the output logic.
module "email_identity_data" {
  source = "../data"

  email_verification_method = var.email_verification_method
  name                      = var.name
  sender_email              = var.sender_email

  depends_on = [
    aws_sesv2_email_identity
  ]
}

# Allow AWS Pinpoint to send email on behalf of this email identity.
# Docs: https://docs.aws.amazon.com/pinpoint/latest/developerguide/security_iam_id-based-policy-examples.html#security_iam_resource-based-policy-examples-access-ses-identities
#
# This is a new resource that was added to the terraform aws provider in v5.35.0.
# See https://github.com/hashicorp/terraform-provider-aws/pull/35486
#
# @TODO See https://github.com/navapbc/template-infra/issues/724
# Until we update, you have to manually attach the generated policy in the AWS console by
# going to Pinpoint > Email > Email identities and following the on-screen banners.
# This has been verified to be working when using v5.61.0.

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# resource "aws_sesv2_email_identity_policy" "sender" {
#   email_identity = aws_sesv2_email_identity.sender.email_identity
#   policy_name    = "PinpointEmail"

#   policy = <<EOF
# {
#   "Version": "2008-10-17",
#   "Statement": [
#     {
#       "Sid": "PinpointEmail",
#       "Effect": "Allow",
#       "Principal":{
#         "Service": "pinpoint.amazonaws.com"
#       },
#       "Action": "ses:*",
#       "Resource": "${aws_sesv2_email_identity.sender.arn}",
#       "Condition": {
#         "StringEquals": {
#           "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
#         },
#         "StringLike": {
#           "aws:SourceArn": "arn:aws:mobiletargeting:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/*"
#         }
#       }
#     }
#   ]
# }
# EOF
# }
