variable "name" {
  type        = string
  description = "The name of an existing cognito user pool"
}

variable "client_secret_ssm_name" {
  type        = string
  description = "The name of the SSM parameter storing the existing user pool client secret"
}

variable "user_pool_access_policy_name" {
  value       = aws_iam_policy.cognito_access.arn
  description = "The name of the IAM policy that grants access to the existing user pool"
}

