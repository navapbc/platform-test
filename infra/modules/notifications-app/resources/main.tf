resource "aws_pinpoint_app" "app" {
  name = var.name
}

resource "aws_pinpoint_email_channel" "app" {
  application_id    = aws_pinpoint_app.app.application_id
  configuration_set = var.email_identity_config
  from_address      = var.sender_email != null ? (var.sender_display_name != null ? "${var.sender_display_name} <${var.sender_email}>" : var.sender_email) : null
  identity          = var.domain_identity_arn
}
