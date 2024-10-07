# Notifications configuration
locals {
  notifications_config = var.enable_notifications ? {
    # Pinpoint app name.
    name = "${var.app_name}-${var.environment}"

    # The method to use to verify the sender email address.
    # - Must be 'email' or 'domain'.
    # - If method is 'email', AWS will send you an email with a one-time link. Click on
    #   the link to verify the email address.
    # - If method is 'domain', then custom domains are required and the domain used will
    #   match the one set in the env-config. See /docs/infra/set-up-custom-domains.md
    # Docs: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-email-manage-verify.html
    email_verification_method = "domain"

    # Configure the name that users see in the "From" section of their inbox, so that it's
    # clearer who the email is from.
    sender_display_name = "coilysiren"

    # Set to the email address to be used when sending emails.
    # - If enable_notifications is true, this is required.
    # - If email_verification_method is set to 'domain', make sure the domain name of the
    #   sender_email matches the domain provided in the env-config.
    # Docs: https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-email.html
    sender_email = "kaisiren@navapbc.com"

    # Configure the REPLY-TO email address if it should be different from the sender.
    # Note: Only used by the identity-provider service.
    reply_to_email = null
  } : null
}
