variable "project_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "environment" {
  description = "name of the application environment (e.g. dev, staging, prod)"
  type        = string
}

variable "network_name" {
  description = "Human readable identifier of the network / VPC"
  type        = string
}

variable "default_region" {
  description = "default region for the project"
  type        = string
}

variable "has_database" {
  type = bool
}

variable "has_incident_management_service" {
  type = bool
}

variable "service_cpu" {
  type    = number
  default = 256
}

variable "service_memory" {
  type    = number
  default = 512
}

variable "service_desired_instance_count" {
  type    = number
  default = 1
}

variable "file_upload_job_overrides" {
  type = map(object({
    source_bucket = optional(string)
    path_prefix   = string
    task_command  = list(string)
  }))

  description = <<EOT
    Override default job configurations for the environment.
    Default job configs are defined in job-configs.tf.
    Add a new job by passing in job configs with new keys,
    modify an existing job by passing in job config with an existing key,
    or remove jobs by passing in null with an existing key

    If source_bucket is not specified, it will be set to
    the storage bucket.
  EOT

  default = {}
}
