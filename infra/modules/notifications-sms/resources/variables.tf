variable "name" {
  type        = string
  description = "Name to give the notifications-sms module."
}

variable "sms_sender_phone_number_registration_id" {
  type        = string
  description = <<-EOF
    The registration ID for the phone number to use as the sender in SMS messages. This value is obtained in AWS
    and the registration must be in APPROVED or COMPLETE status to be linked.
  EOF
  default     = null
}

variable "sms_number_type" {
  type        = string
  description = "The type of phone number to use for sending SMS messages (LONG_CODE, TOLL_FREE, TEN_DLC, SIMULATOR)."
  default     = "SIMULATOR"
}

variable "sms_simulator_phone_number_id" {
  type        = string
  description = "A simulator phone number id to use for sending SMS messages. Used when sms_sender_phone_number_registration_id is not provided."
  default     = null
}
