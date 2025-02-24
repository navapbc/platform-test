locals {
  monitoring_config = {
    email_alert_recipients = var.email_alert_recipients
    incident_management_service = var.has_incident_management_service ? {
      integration_url_param_name = "/monitoring/${var.app_name}/${var.environment}/incident-management-integration-url"
    } : null
  }
}

