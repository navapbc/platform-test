# Create the AWS Pinpoint application.
resource "aws_pinpoint_app" "app" {
  name = var.name
}

# The AWS Pinpoint Email channel requires sender identity verification. It supports:
# 1. email address verification: Verify an email address. An email is sent to the email
#    address with a link to verify you own the email address.
# 2. domain verification: Verify an entire domain. When you verify a new domain, AWS
#    provides a set of DNS records. You have to add these records to the DNS configuration
#    of the domain.
resource "aws_pinpoint_email_channel" "app" {
  application_id    = aws_pinpoint_app.app.application_id
  configuration_set = aws_sesv2_configuration_set.email.configuration_set_name
  from_address      = var.sender_email != null ? (var.sender_display_name != null ? "${var.sender_display_name} <${var.sender_email}>" : var.sender_email) : null
  identity          = aws_sesv2_email_identity.sender.arn
}
