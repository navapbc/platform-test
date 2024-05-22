resource "aws_iam_policy" "access_policy" {
  name        = local.access_policy_name
  description = "IAM policy for accessing the secret ${local.secret.name}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : local.secret.arn
      }
    ]
  })
}
