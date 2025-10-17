# Resource-based policy removed - applications now access SES directly via IAM policies
# Previously allowed Pinpoint to send email on behalf of this email identity
# No resource-based policy is needed since applications use their own IAM credentials
