resource "random_password" "secret" {
  count = var.import_path == null ? 1 : 0

  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "secret" {
  count = var.import_path == null ? 1 : 0

  name  = var.name
  type  = "SecureString"
  value = random_password.secret[0].result
}

data "aws_ssm_parameter" "imported_secret" {
  count = var.import_path != null ? 1 : 0

  name = var.import_path
}
