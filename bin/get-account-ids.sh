#!/bin/bash
# Given a list of account names print out the accoutn ids for each
# For each account name, searches for a file in infra/accounts/ with the name
# <ACCOUNT_NAME>.<ACCOUNT_ID>.s3.tfbackend
# If an account name isn't found, it is ignored
set -euo pipefail
ACCOUNT_NAMES=$*

ACCOUNT_IDS=()
for ACCOUNT_NAME in $ACCOUNT_NAMES; do
  # We use script dir to make this script agnostic to where it's called from.
  # This is needed since this script its called from infra/<app>/build-repository
  # in an external data source
  SCRIPT_DIR=$(dirname $0)
  BACKEND_CONFIG_FILE_GLOB="$SCRIPT_DIR"/../infra/accounts/"$ACCOUNT_NAME".*.s3.tfbackend
  if [ ! -e $BACKEND_CONFIG_FILE_GLOB ]; then
    continue
  fi

  BACKEND_CONFIG_FILE_PATH=$(ls -1 $BACKEND_CONFIG_FILE_GLOB)
  BACKEND_CONFIG_FILE=$(basename "$BACKEND_CONFIG_FILE_PATH")
  BACKEND_CONFIG_NAME="${BACKEND_CONFIG_FILE/.s3.tfbackend/}"
  ACCOUNT_ID="${BACKEND_CONFIG_NAME/$ACCOUNT_NAME./}"
  ACCOUNT_IDS+=("$ACCOUNT_ID")
done

# Print result as a JSON map that looks like {"account_ids": "XXXX YYYY ZZZZ"]}
echo "{\"account_ids\": \"${ACCOUNT_IDS[*]}\"}"
