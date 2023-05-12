#!/bin/bash
# -----------------------------------------------------------------------------
# This script configures the network module by creating the .tfvars file and
# .tfbackend file for the module.
#
# Depending on the project, a project may want a separate network for each
# environment.
#
# Positional parameters:
#   NETWORK_NAME (required) – the name of network to configure
# -----------------------------------------------------------------------------
set -euo pipefail

NETWORK_NAME=$1

#--------------------------------------
# Create terraform backend config file
#--------------------------------------

MODULE_DIR="infra/network"
CONFIG_NAME=$NETWORK_NAME

./bin/create-tfbackend.sh $MODULE_DIR $CONFIG_NAME

#--------------------
# Create tfvars file
#--------------------

TF_VARS_FILE="$MODULE_DIR/$CONFIG_NAME.tfvars"

# Get the name of the S3 bucket that was created to store the tf state
# and the name of the DynamoDB table that was created for tf state locks.
# This will be used to configure the S3 backends in all the application
# modules
REGION=$(terraform -chdir=infra/accounts output -raw region)


echo "======================================"
echo "Setting up tfvars file for app service"
echo "======================================"
echo "Input parameters"
echo "  NETWORK_NAME=$NETWORK_NAME"
echo

cp $MODULE_DIR/example.tfvars $TF_VARS_FILE
sed -i.bak "s/<REGION>/$REGION/g" $TF_VARS_FILE
rm $TF_VARS_FILE.bak

echo "Created file: $TF_VARS_FILE"
echo "------------------ file contents ------------------"
cat $TF_VARS_FILE
echo "----------------------- end -----------------------"
