environment_name     = "dev"
tfstate_bucket       = "platform-test-430004246987-us-east-1-tf"
tfstate_key          = "infra/app/service/dev.tfstate"
region               = "us-east-1"
db_vars = {
  db_access_policy_arn = "arn:aws:iam::430004246987:policy/lorenyudb-app-dev-db-access"
  db_security_group_id = "sg-0df422b6ec9246252"
  db_service_env_vars = {"DB_HOST":"lorenyudb-app-dev.cluster-cluxgx4shg5c.us-east-1.rds.amazonaws.com","DB_NAME":"app","DB_PORT":5432,"DB_USER":"app"}
}
