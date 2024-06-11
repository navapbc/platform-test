#!/bin/bash
# -----------------------------------------------------------------------------
# Convenience script for running terraform init followed by terraform apply
# See ./bin/terraform-init.sh and ./bin/terraform-apply.sh for more details.
#
# Positional parameters:
# module_dir (required) – The location of the root module to initialize and apply
# config_name (required) – The name of the tfbackend and tfvars config. The name
#   is expected to be consistent for both the tfvars file and the tfbackend file.
# -----------------------------------------------------------------------------
set -euo pipefail

module_dir="$1"
config_name="$2"

# Convenience script for running terraform init and terraform apply
# config_name – the name of the backend config.
# For example if a backend config file is named "myaccount.s3.tfbackend", then the config_name would be "myaccount"
# module_dir – the location of the root module to initialize and apply

./bin/terraform-init.sh "$module_dir" "$config_name"

./bin/terraform-apply.sh "$module_dir" "$config_name"
