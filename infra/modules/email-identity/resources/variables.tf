variable "email_verification_method" {
  type        = string
  description = "The method to use to verify the sender email address"
  default     = "email"
  validation {
    condition     = can(regex("^(email|domain)$", var.email_verification_method))
    error_message = "email_verification_method must be either 'email' or 'domain'"
  }
}

variable "name" {
  type        = string
  description = "Name of the notifications project/application"
}

variable "sender_email" {
  type        = string
  description = "Email address to use to send notification emails"
}
