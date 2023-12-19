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
          "${aws_ecs_task_definition.app.arn_without_revision}:*"
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
