locals {
  # The `cron` here is the literal name of the scheduled job. It can be anything you want.
  # For example "file_upload_jobs" or "daily_report". Whatever makes sense for your use case.
  # The `task_command` is what you want your scheduled job to run, for example: ["poetry", "run", "flask"].
  # Schedule expression defines the frequency at which the job should run.
  # The syntax for `schedule_expression` is explained in the following documentation:
  # https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html
  scheduled_jobs = {
    process_dde_metrics_queue = {
      task_command = [
        "sh", "-c",
        join(" ", [
          "cd $PYTHONPATH && python -m scripts.process_dde_metrics_queue",
          "--queue-url \"$DDE_METRICS_QUEUE_URL\"",
          "--destination-bucket-name \"$DDE_METRICS_BUCKET_NAME\"",
          "--max-messages ${local.metrics_max_messages}",
          "--max-batches ${local.metrics_max_batches}",
          "--log-level ${local.metrics_log_level}"
        ])
      ]
      schedule_expression = local.metrics_schedule_expression
    }
  }

  metrics_schedule_expression = "rate(5 minutes)"
  metrics_max_messages = 10
  metrics_max_batches  = 10
  metrics_log_level    = "INFO"
}
