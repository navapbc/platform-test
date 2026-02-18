locals {
  notifications_config = local.environment_config.notifications_config
  sms_config           = local.environment_config.sms_config

  # If this is a temporary environment, re-use an existing email identity. Otherwise, create a new one.
  domain_identity_arn = local.notifications_config != null ? (
    !local.is_temporary ?
    module.notifications_email_domain[0].domain_identity_arn :
    module.existing_notifications_email_domain[0].domain_identity_arn
  ) : null
  notifications_environment_variables = local.notifications_config != null ? {
    AWS_SES_FROM_EMAIL = module.notifications[0].from_email
  } : {}
  notifications_app_name = local.notifications_config != null ? "${local.prefix}${local.notifications_config.name}" : ""

  #SMS environment variables for notifications-sms module
  sms_environment_variables = local.sms_config != null ? {
    AWS_SMS_CONFIGURATION_SET_NAME = module.notifications_sms[0].configuration_set_name
    AWS_SMS_PHONE_POOL_ARN         = module.notifications_sms[0].sms_phone_pool_arn
    AWS_SMS_PHONE_POOL_ID          = module.notifications_sms[0].sms_phone_pool_id

  } : {}
  sms_app_name = local.sms_config != null ? "${local.prefix}${local.sms_config.name}" : ""
}

# If the app has `enable_sms_notifications` set to true, create SMS notification resources.
# A new SMS configuration is created for all environments, including temporary environments.
module "notifications_sms" {
  count  = local.sms_config != null ? 1 : 0
  source = "../../modules/notifications-sms/resources"

  name                                    = local.sms_app_name
  sms_sender_phone_number_registration_id = local.sms_config.sms_sender_phone_number_registration_id
  sms_number_type                         = local.sms_config.sms_number_type
  sms_simulator_phone_number_id           = local.sms_config.sms_simulator_phone_number_id
}

# If the app has `enable_notifications` set to true AND this is not a temporary
# environment, then create a email notification identity.
module "notifications_email_domain" {
  count  = local.notifications_config != null && !local.is_temporary ? 1 : 0
  source = "../../modules/notifications-email-domain/resources"

  domain_name    = module.domain.domain_name
  hosted_zone_id = module.domain.hosted_zone_id
}

# If the app has `enable_notifications` set to true AND this *is* a temporary
# environment, then create a email notification identity.
module "existing_notifications_email_domain" {
  count  = local.notifications_config != null && local.is_temporary ? 1 : 0
  source = "../../modules/notifications-email-domain/data"

  domain_name = module.domain.domain_name
}

# If the app has `enable_notifications` set to true, create IAM policies for SES access.
# A new policy is created for all environments, including temporary environments.
module "notifications" {
  count  = local.notifications_config != null ? 1 : 0
  source = "../../modules/notifications/resources"

  name                = local.notifications_app_name
  domain_identity_arn = local.domain_identity_arn
  sender_display_name = local.notifications_config.sender_display_name
  sender_email        = local.notifications_config.sender_email
}
