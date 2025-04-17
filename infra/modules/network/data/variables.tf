variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "name" {
  type        = string
  description = "The name of the VPC"
}

variable "enable_waf" {
  type        = bool
  description = "Whether to enable AWS Web Application Firewall (WAF) for ALBs in this network."
  default     = true
}
