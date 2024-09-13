#-----------------
# Background Jobs
#-----------------
# CloudWatch Event Rules and CloudWatch Event Targets that define event-based
# triggers for background jobs, such as jobs that trigger when a file is
# uploaded to an S3 bucket or jobs that trigger on a specified "cron" schedule.
#
# For each job configuration, there is a single event rule and an associated
# event target
#

# Event rules that trigger whenever an object is created in S3
# for a particular source bucket and object key prefix
resource "aws_cloudwatch_event_rule" "file_upload_jobs" {
  for_each = var.file_upload_jobs

  name        = "${local.cluster_name}-${each.key}"
  description = "File uploaded to bucket ${each.value.source_bucket} with path prefix ${each.value.path_prefix}"

  event_pattern = jsonencode({
    source      = ["aws.s3"],
    detail-type = ["Object Created"],
    detail = {
      bucket = {
        name = [each.value.source_bucket]
      },
      object = {
        key = [{
          prefix = each.value.path_prefix
        }]
      }
    }
  })
}

# Event target for each event rule that specifies what task command to run

resource "aws_cloudwatch_event_target" "document_upload_jobs" {
  for_each = var.file_upload_jobs

  target_id = "${local.cluster_name}-${each.key}"
  rule      = aws_cloudwatch_event_rule.file_upload_jobs[each.key].name
  arn       = aws_sfn_state_machine.file_upload_jobs[each.key].arn
  role_arn  = aws_iam_role.events.arn
}

resource "aws_sfn_state_machine" "file_upload_jobs" {
  for_each = var.file_upload_jobs

  name     = "${var.service_name}-${each.key}"
  role_arn = aws_iam_role.workflow_orchestrator.arn

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
                "Name" : local.container_name,
                "Command" : each.value.task_command
              }
            ]
          }
        },
        "End" : true
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.file_upload_jobs[each.key].arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  tracing_configuration {
    enabled = true
  }
}

resource "aws_cloudwatch_log_group" "file_upload_jobs" {
  for_each = var.file_upload_jobs

  name_prefix = "/aws/vendedlogs/states/${var.service_name}-${each.key}"

  # Conservatively retain logs for 5 years.
  # Looser requirements may allow shorter retention periods
  retention_in_days = 1827

  # TODO(https://github.com/navapbc/template-infra/issues/164) Encrypt with customer managed KMS key
  # checkov:skip=CKV_AWS_158:Encrypt service logs with customer key in future work
}
