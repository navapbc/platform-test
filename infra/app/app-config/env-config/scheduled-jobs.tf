locals {
  # See `infra/modules/service/variables.tf` for the format of the scheduled_jobs object
  scheduled_jobs = [
    {
      name                         = "${var.app_name}-${var.environment}-show-files"
      command                      = ["ls"]
      schedule_expression          = "rate(1 hour)"
      schedule_expression_timezone = "America/New_York"
      maximum_retry_attempts       = 0
    }
  ]
}
