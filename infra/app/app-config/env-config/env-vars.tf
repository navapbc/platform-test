locals {
  # Map from environment variable name to environment variable value
  # This is a map rather than a list so that variables can be easily
  # overridden per environment using terraform's `merge` function
  default_extra_environment_variables = {

  }

  # Configuration for secrets
  # List of secret names. The names will be used to define environment variables that
  # pull from SSM parameter store. The environment variable name will be the secret
  # name converted to upper case, with dashes replaced by underscores. The SSM parameter
  # name will be "/<APP_NAME>/<ENVIRONMENT_NAME>/<SECRET_NAME>"
  secrets = [

  ]
}
