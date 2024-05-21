variable "name" {
  type        = string
  description = "Fully qualified name of the secret. Can be a path, e.g. /secret/env/my-secret."
}

variable "import_path" {
  type        = string
  description = "If the secret defined in SSM, the path of the secret. If null, generate a new secret. Defaults to null."
  default     = null
}
