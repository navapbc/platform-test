output "configuration_set_name" {
  description = "The name of the AWS End User Messaging SMS configuration set."
  value       = aws_cloudformation_stack.sms_config_set.outputs["ConfigSetName"]
}

output "access_policy_arn" {
  description = "The ARN of the IAM policy for sending SMS via AWS End User Messaging."
  value       = aws_iam_policy.sms_access.arn
}

output "sms_phone_pool_arn" {
  description = "The ARN of the AWS End User Messaging SMS phone pool."
  value       = aws_cloudformation_stack.sms_config_set.outputs["PhonePoolArn"]
}

output "sms_phone_pool_id" {
  description = "The ID of the AWS End User Messaging SMS phone pool."
  value       = aws_cloudformation_stack.sms_config_set.outputs["PhonePoolId"]
}

output "sms_phone_number_id" {
  description = "The ID of the SMS phone number created by CloudFormation."
  value       = aws_cloudformation_stack.sms_config_set.outputs["PhoneNumberId"]
}

output "sms_phone_number_arn" {
  description = "The ARN of the SMS phone number created by CloudFormation."
  value       = aws_cloudformation_stack.sms_config_set.outputs["PhoneNumberArn"]
}