# The AWS Pinpoint Email channel requires sender identity verification. It supports:
# 1. email address verification: Verify an email address. An email is sent to the email
#    address with a link to verify you own the email address.
# 2. domain verification: Verify an entire domain. When you verify a new domain, AWS
#    provides a set of DNS records. You have to add these records to the DNS configuration
#    of the domain.
resource "aws_pinpoint_email_channel" "email" {
  application_id    = aws_pinpoint_app.app.application_id
  configuration_set = var.email_configuration_set_name
  from_address      = var.sender_email != null ? (var.sender_display_name != null ? "${var.sender_display_name} <${var.sender_email}>" : var.sender_email) : null
  identity          = var.email_identity_arn

  # Note: There is a known bug where role_arn isn't being persisted to AWS. This means
  # that this module will always show that there are changes that haven't been applied.
  # Commenting it out for now.
  # See https://github.com/hashicorp/terraform-provider-aws/issues/38772
  # role_arn          = aws_iam_role.analytics.arn
}
