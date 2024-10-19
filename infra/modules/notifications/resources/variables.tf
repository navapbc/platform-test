variable "email_verification_method" {
  type        = string
  description = "The method to use to verify the sender email address"
  default     = "domain"
  validation {
    condition     = can(regex("^(domain)$", var.email_verification_method))
    error_message = "email_verification_method must be either or 'domain'"
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
