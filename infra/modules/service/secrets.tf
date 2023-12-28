data "aws_ssm_parameter" "secret" {
  for_each = var.secret_names
  name     = "/${var.service_name}/${each.key}"
}

locals {
  secrets = [
    for secret_name in var.secret_names :
    { name = upper(replace(secret_name, "-", "_")), valueFrom = data.aws_ssm_parameter.secret[secret_name].arn }
  ]
}
