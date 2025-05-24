output "domain_identity_arn" {
  value = data.aws_sesv2_email_identity.main.arn
}

output "ses_access_policy_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${replace(var.domain_name, ".", "-")}-ses-access"
}
