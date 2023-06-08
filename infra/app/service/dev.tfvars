environment_name = "dev"
tfstate_bucket   = "platform-test-430004246987-us-east-1-tf"
tfstate_key      = "infra/app/service/dev.tfstate"
region           = "us-east-1"
db_vars = {
  access_policy_arn = "arn:aws:iam::430004246987:policy/app-dev-db-access"
  security_group_id = "sg-05c32a93b2c742cc9"
  connection_info = {
    host        = "app-dev.cluster-cluxgx4shg5c.us-east-1.rds.amazonaws.com"
    port        = "5432"
    user        = "app"
    db_name     = "app"
    schema_name = "app"
  }
}
