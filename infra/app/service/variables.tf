variable "environment_name" {
  type        = string
  description = "name of the application environment"
}

variable "image_tag" {
  type        = string
  description = "image tag to deploy to the environment"
  default     = null
}

variable "tfstate_bucket" {
  type = string
}

variable "tfstate_key" {
  type = string
}

variable "region" {
  type = string
}

variable "db_security_group_id" {
  type = string
}

variable "db_access_policy_arn" {
  type = string
}

variable "db_service_env_vars" {
  type = map(string)
}
