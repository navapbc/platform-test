variable "domain_name" {
  description = "The domain name to configure SES, also used as the resource names"
  type        = string
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
