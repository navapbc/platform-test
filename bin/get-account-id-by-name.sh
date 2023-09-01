#!/bin/bash
# Print the AWS account id for the account with a given name
# Searches for a file in infra/accounts/ with the name <ACCOUNT_NAME>.<ACCOUNT_ID>.s3.tfbackend
# and returns <ACCOUNT_ID>
set -euo pipefail
ACCOUNT_NAME=$1

# We use script dir to make this script agnostic to where it's called from.
# This is needed since this script its called from infra/<app>/build-repository
# in an external data source
SCRIPT_DIR=$(dirname $0)
BACKEND_CONFIG_FILE_GLOB="$SCRIPT_DIR"/../infra/accounts/"$ACCOUNT_NAME".*.s3.tfbackend
if [ ! -e $BACKEND_CONFIG_FILE_GLOB ]; then
  echo "null"
else
  BACKEND_CONFIG_FILE_PATH=$(ls -1 $BACKEND_CONFIG_FILE_GLOB)
  BACKEND_CONFIG_FILE=$(basename "$BACKEND_CONFIG_FILE_PATH")
  BACKEND_CONFIG_NAME="${BACKEND_CONFIG_FILE/.s3.tfbackend/}"
  ACCOUNT_ID="${BACKEND_CONFIG_NAME/$ACCOUNT_NAME./}"
  echo -n "{\"account_id\": \"$ACCOUNT_ID\"}"
fi
