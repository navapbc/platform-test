resource "aws_cloudwatch_event_rule" "document_upload_jobs" {
  for_each = var.document_upload_jobs

  name        = "${local.prefix}-${each.key}"
  description = "Trigger job ${each.key} in cluster ${var.ecs_cluster_name} when documents are uploaded to bucket ${each.value.source_bucket} with path prefix ${each.value.path_prefix}"

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
  for_each = var.document_upload_jobs

  target_id = "${local.prefix}-${each.key}"
  rule      = aws_cloudwatch_event_rule.document_upload_jobs.name
  arn       = data.aws_ecs_cluster.cluster.arn
  role_arn  = aws_iam_role.events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = var.task_definition_arn
  }

  input = jsonencode({
    containerOverrides = [
      {
        name = "TODO name-of-container-to-override",
        command = [
          "bin/console",
          "scheduled-task"
        ]
      }
    ]
  })
}

