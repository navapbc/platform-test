#!/bin/bash
# -----------------------------------------------------------------------------
# Run migrations
# 
# Positional parameters:
#   APP_NAME (required) – the name of subdirectory of /infra that holds the
#     application's infrastructure code.
#   ENVIRONMENT (required) – the name of the application environment (e.g. dev,
#     staging, prod)
# -----------------------------------------------------------------------------
set -euo pipefail

APP_NAME="$1"
ENVIRONMENT="$2"


echo "=================="
echo "Running migrations"
echo "=================="
echo "Input parameters"
echo "  APP_NAME=$APP_NAME"
echo "  ENVIRONMENT=$ENVIRONMENT"
echo

 
DB_HOST=$(terraform -chdir=infra/$APP_NAME/database output -raw database_host)
DB_PORT=$(terraform -chdir=infra/$APP_NAME/database output -raw database_port)
DB_MIGRATOR_USER=$(terraform -chdir=infra/$APP_NAME/database output -raw migrator_username)
DB_NAME=$(terraform -chdir=infra/$APP_NAME/database output -raw database_name)
DB_SCHEMA=$(terraform -chdir=infra/$APP_NAME/database output -raw schema_name)

COMMAND='["db-migrate"]'

# Indent the later lines more to make the output of run-command prettier
ENVIRONMENT_VARIABLES=$(cat << EOF
[
        { "name" : "DB_HOST", "value" : "$DB_HOST" },
        { "name" : "DB_PORT", "value" : "$DB_PORT" },
        { "name" : "DB_USER", "value" : "$DB_MIGRATOR_USER" },
        { "name" : "DB_NAME", "value" : "$DB_NAME" },
        { "name" : "DB_SCHEMA", "value" : "$DB_SCHEMA" }
      ]
EOF
)

./bin/run-command.sh $APP_NAME $ENVIRONMENT "$COMMAND" "$ENVIRONMENT_VARIABLES"
