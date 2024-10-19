variable "email_configuration_set_name" {
  type        = string
  description = "The name of the SESv2 configuration set to apply to the pinpoint email channel"
}

variable "email_identity_arn" {
  type        = string
  description = "The arn for the SESv2 email identity to use to send emails"
}

variable "email_verification_method" {
  type        = string
  description = "The method to use to verify the sender email address"
  default     = "email"
  validation {
    condition     = can(regex("^(email|domain)$", var.email_verification_method))
    error_message = "email_verification_method must be either 'email' or 'domain'"
  }
}

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
}

variable "sender_display_name" {
  type        = string
  description = "The display name for notification emails. Only used if sender_email is provided"
  default     = null
}
