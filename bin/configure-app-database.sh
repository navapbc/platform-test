#!/bin/bash
# -----------------------------------------------------------------------------
# This script configures the database module for the specified application
# and environment by creating the .tfvars file and .tfbackend file for the module.
#
# Positional parameters:
#   APP_NAME (required) – the name of subdirectory of /infra that holds the
#     application's infrastructure code.
#   ENVIRONMENT is the name of the application environment (e.g. dev, staging, prod)
# -----------------------------------------------------------------------------
set -euo pipefail

APP_NAME=$1
ENVIRONMENT=$2

#--------------------------------------
# Create terraform backend config file
#--------------------------------------

MODULE_DIR="infra/$APP_NAME/database"
BACKEND_CONFIG_NAME="$ENVIRONMENT"

./bin/create-tfbackend.sh "$MODULE_DIR" "$BACKEND_CONFIG_NAME"

#--------------------
# Create tfvars file
#--------------------

TF_VARS_FILE="$MODULE_DIR/$ENVIRONMENT.tfvars"

REGION=$(terraform -chdir=infra/accounts output -raw region)


echo "======================================="
echo "Setting up tfvars file for app database"
echo "======================================="
echo "Input parameters"
echo "  APP_NAME=$APP_NAME"
echo "  ENVIRONMENT=$ENVIRONMENT"
echo

cp "$MODULE_DIR/example.tfvars" "$TF_VARS_FILE"
sed -i.bak "s/<ENVIRONMENT>/$ENVIRONMENT/g" "$TF_VARS_FILE"
sed -i.bak "s/<REGION>/$REGION/g" "$TF_VARS_FILE"
rm "$TF_VARS_FILE.bak"

echo "Created file: $TF_VARS_FILE"
echo "------------------ file contents ------------------"
cat "$TF_VARS_FILE"
echo "----------------------- end -----------------------"