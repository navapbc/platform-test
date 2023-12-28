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
  # name will be "/<SERVICE_NAME>/<SECRET_NAME>"
  # For example, a secret named "secret-sauce" will generate a secret configuration
  # { "name": "SECRET_SAUCE", "valueFrom": "arn:aws:ssm:<REGION>:<AWS_ACCOUNT_ID>:parameter/app-dev/secret-sauce" }
  secret_names = [
    "secret-sauce"
  ]
}
