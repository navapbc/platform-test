# If the app has `enable_notifications` set to true AND this is not a temporary
# environment, then create a email notification identity.
module "notifications" {
  # count  = module.app_config.enable_notifications && !local.is_temporary ? 1 : 0
  count  = terraform.workspace == "p-140" ? 1 : 0 # force creation to test this PR environment
  source = "../../modules/notifications/resources"

  email_verification_method = local.notifications_config.email_verification_method

  name                = "${local.prefix}${local.notifications_config.name}"
  domain_name         = local.service_config.domain_name
  sender_email        = local.notifications_config.sender_email
  sender_display_name = local.notifications_config.sender_display_name
}

# # If the app has `enable_notifications` set to true AND this *is* a temporary
# # environment, then create a email notification identity.
# module "existing_notifications" {
#   count  = module.app_config.enable_notifications && local.is_temporary ? 1 : 0
#   source = "../../modules/notifications/data"

#   name = local.notifications_config.name
# }

# # If the app has `enable_notifications` set to true, create a new email notification
# # identity client for the service. A new client is created for all environments, including
# # temporary environments.
# module "notifications_client" {
#   count  = module.app_config.enable_notifications ? 1 : 0
#   source = "../../modules/notifications/client"

#   email_identity_arn = module.app_config.enable_notifications ? module.notifications[0].email_identity_arn : null
# }
