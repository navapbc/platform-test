variable "name" {
  description = "name of the database cluster. Note that this is not the name of the Postgres database itself, but the name of the cluster in RDS. The name of the Postgres database is set in module and defaults to 'app'."
  validation {
    condition     = can(regex("^[-_\\da-z]+$", var.name))
    error_message = "use only lower case letters, numbers, dashes, and underscores"
  }
}

variable "database_name" {
  description = "the name of the Postgres database. Defaults to 'app'."
  default     = "app"
  validation {
    condition     = can(regex("^[_\\da-z]+$", var.database_name))
    error_message = "use only lower case letters, numbers, and underscores (no dashes)"
  }
}

variable "vpc_id" {
  type        = string
  description = "Uniquely identifies the VPC."
}

variable "ingress_security_group_ids" {
  description = "list of security group IDs from which to allow network traffic to the database"
}
