# Make the "image_tag" variable optional so that "terraform plan"
# and "terraform apply" work without any required variables.
#
# This works as follows:

#  1. Accept an optional variable during a terraform plan/apply. (see "image_tag" variable in variables.tf)

#  2. Read the output used from the last terraform state using "terraform_remote_state".
data "terraform_remote_state" "current_image_tag" {
  # Don't do a lookup if image_tag is provided explicitly.
  # This saves some time and also allows us to do a first deploy,
  # where the tfstate file does not yet exist.
  count   = var.image_tag == null ? 1 : 0
  backend = "s3"

  config = {
    bucket = local.tfstate_bucket
    key    = local.tfstate_key
    region = local.service_config.region
  }

  defaults = {
    image_tag = null
  }
}

#  3. Prefer the given variable if provided, otherwise default to the value from last time.
locals {
  backend_config_file_path = "${path.module}/${var.environment_name}.s3.tfbackend"
  backend_config_file      = file("${path.module}/${var.environment_name}.s3.tfbackend")
  backend_config_regex     = "(\\w+)\\s*=\\s*\\\"(\\w+)\\\""
  backend_config           = { for match in regexall("(\\w+)\\s*=\\s*\\\"(.+)\\\"", local.backend_config_file) : match[0] => match[1] }
  tfstate_bucket           = local.backend_config["bucket"]
  tfstate_key              = local.backend_config["key"]
  image_tag = (var.image_tag == null
    ? data.terraform_remote_state.current_image_tag[0].outputs.image_tag
  : var.image_tag)
}

#  4. Store the final value used as a terraform output for next time.
output "image_tag" {
  value = local.image_tag
}
