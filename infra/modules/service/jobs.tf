# Role that EventBridge will assume
# The role allows EventBridge to run tasks on the ECS cluster
resource "aws_iam_role" "events" {
  name                = "${var.service_name}-events"
  managed_policy_arns = [var.var.run_task_policy_arn]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

# Create policy that allows running tasks on the ECS cluster
resource "aws_iam_policy" "run_task" {
  name = "${var.service_name}-run-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask"
        ],
        Resource = [
          "${aws_ecs_task_definition.app.arn}:*",
          "${aws_ecs_task_definition.app.arn}"
        ],
        Condition = {
          ArnLike = {
            "ecs:cluster" : "${aws_ecs_cluster.cluster.arn}"
          }
        }
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = [
          "*"
        ],
        Condition = {
          StringLike = {
            "iam:PassedToService" : "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "file_upload_jobs" {
  for_each = var.jobs.file_upload_jobs

  name        = "${var.service_name}-${each.key}"
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

resource "aws_cloudwatch_event_target" "document_upload_jobs" {
  for_each = var.jobs.file_upload_jobs

  target_id = "${var.service_name}-${each.key}"
  rule      = aws_cloudwatch_event_rule.file_upload_jobs[each.key].name
  arn       = aws_ecs_cluster.cluster.arn
  role_arn  = aws_iam_role.events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.app.arn
  }

  input = jsonencode({
    containerOverrides = [
      {
        name    = local.container_name,
        command = each.value.task_command
      }
    ]
  })
}
