resource "aws_cloudwatch_log_group" "logs" {
  name = "${var.service_name}-feature-flags"

  # Conservatively retain logs for 5 years.
  # Looser requirements may allow shorter retention periods
  retention_in_days = 1827
}
