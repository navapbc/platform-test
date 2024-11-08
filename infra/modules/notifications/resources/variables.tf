variable "domain_name" {
  description = "The domain name to configure SES."
  type        = string
}

variable "name" {
  type        = string
  description = "Name of the notifications project/application"
}

variable "sender_email" {
  type        = string
  description = "Email address to use to send notification emails"

  validation {
    condition     = regex("^.+@${var.domain_name}$", var.sender_email)
    error_message = "The sender_email value must be an email address from the configured domain."
  }
}

variable "sender_display_name" {
  type        = string
  description = "The display name for notification emails. Only used if sender_email is provided"
  default     = null
}
