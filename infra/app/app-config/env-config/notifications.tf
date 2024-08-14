# Notifications configuration
locals {
  notifications_config = var.enable_notifications ? {
    # Pinpoint app name.
    name = "${var.app_name}-${var.environment}"

    # The method to use to verify the sender email address.
    # - Must be 'email' or 'domain'.
    # - For email, AWS will send you an email with a one-time link. Click on the link to verify the email address.
    # - For domain, create CNAME records for the domain using the DKIM values in the terraform output.
    # Docs: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-email-manage-verify.html
    email_verification_method = "domain"

    # Configure the name that users see in the "From" section of their inbox, so that it's
    # clearer who the email is from.
    sender_display_name = "FOOBAR"

    # Set to an SES-verified email address to be used when sending emails.
    # If enable_notifications is true, this is required.
    # Docs: https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-email.html
    sender_email = "rocket@navateam.com"

    # Configure the REPLY-TO email address if it should be different from the sender.
    # Note: Only used by the identity-provider service.
    reply_to_email = null

    # Set this to `true` if the sender email address identity should be created in the
    # region. To check, use the AWS Console to navigate to: Pinpoint > Email > Email
    # Identities. Otherwise, set this to `false` to use the existing identity.
    create_email_identity = false
  } : null
}
