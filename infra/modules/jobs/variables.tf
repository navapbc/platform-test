variable "id" {
  type        = string
  description = "Prefix to use for infra resources"
}

variable "cluster_name" {
  type        = string
  description = "Name of ECS cluster to run jobs in"
}

variable "task_definition_arn" {
  type        = string
  description = "ARN of the task definition"
}

variable "container_name" {
  type        = string
  description = "Name of the container within the task definition to run the job in"
}

variable "run_task_policy_arn" {
  type        = string
  description = "ARN of IAM policy that allows running tasks in the cluster"
}

variable "app_security_group" {
  type        = string
  description = "Security group for the application"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "List of subnets that the application sits in"
}

variable "file_upload_jobs" {
  type = map(object({
    source_bucket = string
    path_prefix   = string
    task_command  = list(string)
  }))

  description = "File upload jobs"
  default     = {}
}
