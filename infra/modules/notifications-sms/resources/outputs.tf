output "configuration_set_name" {
  description = "The name of the AWS End User Messaging SMS configuration set."
  value       = aws_cloudformation_stack.sms_config_set.outputs["ConfigSetName"]
}

output "access_policy_arn" {
  description = "The ARN of the IAM policy for sending SMS via AWS End User Messaging."
  value       = aws_iam_policy.sms_access.arn
}

output "opt_out_list_name" {
  description = "The name of the AWS End User Messaging SMS opt-out list."
  value       = aws_pinpointsmsvoicev2_opt_out_list.sms_opt_out_list[0].name
}