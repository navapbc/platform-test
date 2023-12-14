# variable "ecs_cluster_name" {

# }

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster. Used to prefix names of resources."
}

variable "task_definition_arn" {
  type        = string
  description = "ARN of the task definition to run jobs."
}


variable "run_task_policy_arn" {
  type        = string
  description = "ARN of the IAM policy that allows running tasks on the ECS cluster"
}

variable "document_upload_jobs" {
  type = map({
    source_bucket = any
    path_prefix   = string
    task_command  = list(string)
  })

  description = "event_name = document_upload, event_source = <BUCKET_NAME>, command gets parameters <BUCKET_NAME>, <OBJECT_KEY>"
}
