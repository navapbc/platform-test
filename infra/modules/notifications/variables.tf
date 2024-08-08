variable "email_configuration_set_name" {
  type = string
  description = "The name of the SESv2 configuration set to apply to the pinpoint email channel"
}

variable "email_identity_arn" {
  type = string
  description = "The arn for the SESv2 email identity to use to send emails"
}

variable "name" {
  type        = string
  description = "The name of the notifications project/application"
}

variable "sender_display_name" {
  type        = string
  description = "The display name for notification emails. Only used if sender_email is provided"
  default     = null
}

variable "sender_email" {
  type        = string
  description = "The email address to use to send notification emails"
}
