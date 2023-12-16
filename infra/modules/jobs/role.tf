# Role that EventBridge will assume
# The role allows EventBridge to run tasks on the ECS cluster
resource "aws_iam_role" "events" {
  name                = "${var.id}-events"
  managed_policy_arns = [var.run_task_policy_arn]

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
