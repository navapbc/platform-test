variable "name" {
  type        = string
  description = "Name to give the notifications-sms module."
}

variable "enable_opt_out_list" {
  type        = bool
  description = "Whether to create an opt-out list for SMS messages."
  default     = true
}

variable "enable_delivery_receipt_logging" {
  type        = bool
  description = "Whether to enable logging of SMS delivery receipts to CloudWatch Logs."
  default     = true
}
