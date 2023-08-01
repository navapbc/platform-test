variable "bucket_policy_document" {
  type = string
  default = "{}"
}
variable "service_name" {
  type = string
  default = "platform-template"
}
variable "ia_storage_after" {
  type = number
  default = 0
}
variable "glacier_storage_after" {
    type = number
    default = 0
}
variable "delete_objects_after" {
  type = number
  default = 0
}
variable "prefix" {
  type = string
  default = ""
}

variable "purpose" {
  type = string
}