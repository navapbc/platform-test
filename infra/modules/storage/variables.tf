variable "is_temporary" {
  description = "Whether the service is meant to be spun up temporarily (e.g. for automated infra tests). This is used to disable deletion protection."
  type        = bool
  default     = false
}

variable "name" {
  type        = string
  description = "Name of the AWS S3 bucket. Needs to be globally unique across all regions."
}

variable "kms_s3_via_service_principals" {
  description = "List of IAM role ARNs that should have KMS access via S3 service (e.g., for Bedrock Data Automation)"
  type        = list(string)
  default     = []
}
