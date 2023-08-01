variable "bucket_policy_document" {
  type = string
  default = "{}"
}
variable "service_name" {
  type = string
  default = "platform-template"
}

variable "transitions" {
  default = []
}

variable "expiration" {
  type = number
  default = 0
}

variable "purpose" {
  type = string
}