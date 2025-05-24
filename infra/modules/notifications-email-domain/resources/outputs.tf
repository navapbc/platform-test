output "domain_identity_arn" {
  value = aws_sesv2_email_identity.sender_domain.arn
}

output "ses_access_policy_arn" {
  value = aws_iam_policy.ses_access.arn
}
