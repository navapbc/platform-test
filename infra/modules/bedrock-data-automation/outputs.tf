output "bda_project_arn" {
  description = "The ARN of the Bedrock Data Analytics project"
  value       = awscc_bedrock_data_automation_project.bda_project.project_arn
}

output "bda_role_name" {
  description = "The name of the IAM role used by Bedrock Data Analytics"
  value       = aws_iam_role.bda_role.name
}

output "bda_role_arn" {
  description = "The ARN of the IAM role used by Bedrock Data Analytics"
  value       = aws_iam_role.bda_role.arn
}