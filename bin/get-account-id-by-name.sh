#!/bin/bash
# Print the AWS account id for the account with a given name
# Searches for a file in infra/accounts/ with the name <ACCOUNT_NAME>.<ACCOUNT_ID>.s3.tfbackend
# and returns <ACCOUNT_ID>
set -euo pipefail
ACCOUNT_NAME=$1

SCRIPT_DIR=$(dirname $0)
BACKEND_CONFIG_FILE_PATH=$(ls -1 "$SCRIPT_DIR"/../infra/accounts/"$ACCOUNT_NAME".*.s3.tfbackend)
BACKEND_CONFIG_FILE=$(basename "$BACKEND_CONFIG_FILE_PATH")
BACKEND_CONFIG_NAME="${BACKEND_CONFIG_FILE/.s3.tfbackend/}"
ACCOUNT_ID="${BACKEND_CONFIG_NAME/$ACCOUNT_NAME./}"
echo -n "$ACCOUNT_ID"
