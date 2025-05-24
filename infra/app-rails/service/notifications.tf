locals {
  notifications_config = local.environment_config.notifications_config

  # If this is a temporary environment, re-use an existing email identity. Otherwise, create a new one.
  domain_identity_arn = local.notifications_config != null ? (
    !local.is_temporary ?
    module.notifications_email_domain[0].domain_identity_arn :
    module.existing_notifications_email_domain[0].domain_identity_arn
  ) : null

  ses_access_policy_arn = local.notifications_config != null ? (
    !local.is_temporary ?
    module.notifications_email_domain[0].ses_access_policy_arn :
    module.existing_notifications_email_domain[0].ses_access_policy_arn
  ) : null

  notifications_environment_variables = local.notifications_config != null ? {
    AWS_SES_SENDER_EMAIL = local.notifications_config.sender_email,
    AWS_SES_REGION       = data.aws_region.current.name
  } : {}
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

data "aws_region" "current" {}

output "ses_sender_email" {
  value = local.notifications_config != null ? local.notifications_config.sender_email : null
}
