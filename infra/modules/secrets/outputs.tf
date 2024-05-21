output "secret_arn" {
  value = var.import_path == null ? aws_ssm_parameter.secret[0].arn : data.aws_ssm_parameter.imported_secret[0].arn
}
