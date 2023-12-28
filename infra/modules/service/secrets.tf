data "aws_ssm_parameter" "secret" {
  for_each = var.secrets
  name     = "/${var.service_name}/${each.key}"
}

locals {
  secrets = [
    for secret in data.aws_ssm_parameter.secret :
    { name = upper(replace(secret, "-", "_")), valueFrom = secret.arn }
  ]
}
