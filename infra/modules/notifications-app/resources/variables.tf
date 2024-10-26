variable "name" {
  type        = string
  description = "Name of the notifications project/application"
}

variable "sender_email" {
  type        = string
  description = "Email address to use to send notification emails"
}

variable "sender_display_name" {
  type        = string
  description = "The display name for notification emails. Only used if sender_email is provided"
  default     = null
}

variable "email_identity_arn" {
  type        = string
  description = "The ARN of the email identity to use for sending emails"
}

variable "email_identity_config" {
  type        = string
  description = "The name of the email configuration set to use for sending emails"
}
