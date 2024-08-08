variable "name" {
  type        = string
  description = "Name of the notifications project/application"
}

variable "sender_display_name" {
  type        = string
  description = "The display name for notification emails. Only used if sender_email is provided"
  default     = null
}

variable "sender_email" {
  type        = string
  description = "Email address to use to send notification emails"
}
