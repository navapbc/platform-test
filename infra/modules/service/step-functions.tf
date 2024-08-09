# docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "sfn_cron_job" {
  for_each = {
    for index, sfn_vars in var.sfn_vars :
    sfn_vars.name => sfn_vars
  }

  name_prefix = "/aws/vendedlogs/states/${var.service_name}-${each.value.name}"

  # Conservatively retain logs for 5 years.
  # Looser requirements may allow shorter retention periods
  retention_in_days = 1827

  # TODO(https://github.com/navapbc/template-infra/issues/164) Encrypt with customer managed KMS key
  # checkov:skip=CKV_AWS_158:Encrypt service logs with customer key in future work
}

# docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine
resource "aws_sfn_state_machine" "sfn_cron_job" {
  for_each = {
    for index, sfn_vars in var.sfn_vars :
    sfn_vars.name => sfn_vars
  }

  name     = "${var.service_name}-${each.value.name}"
  role_arn = module.service.task_role_arn

  definition = jsonencode({
    "StartAt" : "ExecuteECSTask",
    "States" : {
      "ExecuteECSTask" : {
        "Type" : "Task",
        # docs: https://docs.aws.amazon.com/step-functions/latest/dg/connect-ecs.html
        "Resource" : "arn:aws:states:::ecs:runTask.sync",
        "Parameters" : {
          "Cluster" : module.service.cluster_arn,
          "TaskDefinition" : module.service.task_definition_arn,
          "LaunchType" : "FARGATE",
          "NetworkConfiguration" : {
            "AwsvpcConfiguration" : {
              "Subnets" : data.aws_subnets.private.ids,
              "SecurityGroups" : [module.service.app_security_group_id],
            }
          },
          "Overrides" : {
            "ContainerOverrides" : [
              {
                "Name" : var.service_name,
                "Environment" : each.value.environment
                "Command" : each.value.command
              }
            ]
          }
        },
        "End" : true
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_cron_job[each.key].arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  tracing_configuration {
    enabled = true
  }
}

# docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule_group
resource "aws_scheduler_schedule_group" "sfn_cron_job" {
  for_each = {
    for index, sfn_vars in var.sfn_vars :
    sfn_vars.name => sfn_vars
  }

  name = "${var.service_name}-${each.value.name}"
}

# docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule
resource "aws_scheduler_schedule" "sfn_cron_job" {
  for_each = {
    for index, sfn_vars in var.sfn_vars :
    sfn_vars.name => sfn_vars
  }

  # TODO(https://github.com/navapbc/template-infra/issues/164) Encrypt with customer managed KMS key
  # checkov:skip=CKV_AWS_158:Encrypt service logs with customer key in future work

  name                         = "${var.service_name}-${each.value.name}"
  state                        = "ENABLED"
  group_name                   = aws_scheduler_schedule_group.sfn_cron_job[each.key].id
  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone

  flexible_time_window {
    mode = "OFF"
  }

  # target is the state machine
  target {
    arn      = aws_sfn_state_machine.sfn_cron_job[each.key].arn
    role_arn = module.service.task_role_arn

    retry_policy {
      maximum_retry_attempts = each.value.maximum_retry_attempts
    }
  }
}
