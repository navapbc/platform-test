# Notifications configuration
locals {
  notifications_config = var.enable_notifications ? {
    # Pinpoint app name.
    name = "${var.app_name}-${var.environment}"

    # Configure the name that users see in the "From" section of their inbox,
    # so that it's clearer who the email is from.
    sender_display_name = "Kai Siren"

    # Set to the email address to be used when sending emails.
    # If enable_notifications is true, this is required.
    sender_email = "coilysiren@not-my-domain-name.com"

    # Configure the REPLY-TO email address if it should be different from the sender.
    reply_to_email = "coilysiren@${var.domain_name}"
  } : null
}
