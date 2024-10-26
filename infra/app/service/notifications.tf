locals {
  # If this is a temporary environment, re-use an existing email identity. Otherwise, create a new one.
  email_identity_arn = module.app_config.enable_notifications ? (
    !local.is_temporary ? module.notifications[0].email_identity_arn : module.existing_notifications[0].email_identity_arn
  ) : null
  email_identity_config = module.app_config.enable_notifications ? (
    !local.is_temporary ? module.notifications[0].email_identity_config : module.existing_notifications[0].email_identity_config
  ) : null
  notifications_environment_variables = module.app_config.enable_notifications ? {
    PINPOINT_APP_ID = module.notifications_app[0].app_id,
    PINPOINT_SENDER = local.notifications_config.sender_email
  } : {}
}

# If the app has `enable_notifications` set to true AND this is not a temporary
# environment, then create a email notification identity.
module "notifications" {
  count  = module.app_config.enable_notifications && !local.is_temporary ? 1 : 0
  source = "../../modules/notifications/resources"

  domain_name         = local.service_config.domain_name
  name                = local.notifications_config.name
  sender_email        = local.notifications_config.sender_email
  sender_display_name = local.notifications_config.sender_display_name
}

# If the app has `enable_notifications` set to true AND this *is* a temporary
# environment, then create a email notification identity.
module "existing_notifications" {
  count  = module.app_config.enable_notifications && local.is_temporary ? 1 : 0
  source = "../../modules/notifications/data"

  name        = local.notifications_config.name
  domain_name = local.service_config.domain_name
}

# If the app has `enable_notifications` set to true, create a new email notification
# AWS Pinpoint app for the service. A new app is created for all environments, including
# temporary environments.
module "notifications_app" {
  count  = module.app_config.enable_notifications ? 1 : 0
  source = "../../modules/notifications-app/resources"

  name                  = local.notifications_config.name
  email_identity_arn    = local.email_identity_arn
  email_identity_config = local.email_identity_config
  sender_display_name   = local.notifications_config.sender_display_name
  sender_email          = local.notifications_config.sender_email
}
