locals {
  # The command you want you step function to run, for example: ["poetry", "run", "flask"]
  # Schedule expression defined the frequency at which the job should run.
  # The syntax for schedule expression is explained in the following documentation:
  # https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html
  # TODO: remove app_name and environment from name, fill then in via the module
  # TODO: command that invokes the docker app
  # TODO: use cron schedule expression
  scheduled_jobs = {
    show-files = {
      task_command        = ["ls"]
      schedule_expression = "rate(1 hour)"
    }
  }
}
