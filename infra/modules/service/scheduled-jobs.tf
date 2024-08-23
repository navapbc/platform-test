resource "aws_sfn_state_machine" "scheduled_job" {
  for_each = var.scheduled_jobs

  name     = "${var.service_name}-${each.key}"
  role_arn = aws_iam_role.app_service.arn

  definition = jsonencode({
    "StartAt" : "RunTask",
    "States" : {
      "RunTask" : {
        "Type" : "Task",
        # docs: https://docs.aws.amazon.com/step-functions/latest/dg/connect-ecs.html
        "Resource" : "arn:aws:states:::ecs:runTask.sync",
        "Parameters" : {
          "Cluster" : aws_ecs_cluster.cluster.arn,
          "TaskDefinition" : aws_ecs_task_definition.app.arn,
          "LaunchType" : "FARGATE",
          "NetworkConfiguration" : {
            "AwsvpcConfiguration" : {
              "Subnets" : var.private_subnet_ids,
              "SecurityGroups" : [aws_security_group.app.id],
            }
          },
          "Overrides" : {
            "ContainerOverrides" : [
              {
                "Name" : var.service_name,
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
    log_destination        = "${aws_cloudwatch_log_group.scheduled_job[each.key].arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  tracing_configuration {
    enabled = true
  }
}

resource "aws_scheduler_schedule_group" "scheduled_job" {
  for_each = var.scheduled_jobs

  name = "${var.service_name}-${each.key}"
}

resource "aws_scheduler_schedule" "scheduled_job" {
  for_each = var.scheduled_jobs

  # TODO(https://github.com/navapbc/template-infra/issues/164) Encrypt with customer managed KMS key
  # checkov:skip=CKV_AWS_297:Encrypt with customer key in future work

  name                         = "${var.service_name}-${each.key}"
  state                        = "ENABLED"
  group_name                   = aws_scheduler_schedule_group.scheduled_job[each.key].id
  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone

  flexible_time_window {
    mode = "OFF"
  }

  # target is the state machine
  target {
    arn      = aws_sfn_state_machine.scheduled_job[each.key].arn
    role_arn = aws_iam_role.app_service.arn

    retry_policy {
      maximum_retry_attempts = each.value.maximum_retry_attempts
    }
  }
}

resource "aws_cloudwatch_log_group" "scheduled_job" {
  for_each = var.scheduled_jobs

  name_prefix = "/aws/vendedlogs/states/${var.service_name}-${each.key}"

  # Conservatively retain logs for 5 years.
  # Looser requirements may allow shorter retention periods
  retention_in_days = 1827

  # TODO(https://github.com/navapbc/template-infra/issues/164) Encrypt with customer managed KMS key
  # checkov:skip=CKV_AWS_158:Encrypt service logs with customer key in future work
}
