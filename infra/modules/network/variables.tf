variable "name" {
  type        = string
  description = "Name to give the VPC. Will be added to the VPC under the 'network_name' tag."
}

variable "aws_services_security_group_name_prefix" {
  type        = string
  description = "Prefix for the name of the security group attached to VPC endpoints"
}

variable "database_subnet_group_name" {
  type        = string
  description = "Name of the database subnet group"
}

variable "has_database" {
  type        = bool
  description = "Whether the application(s) in this network have a database. Determines whether to create VPC endpoints needed by the database layer."
  default     = false
}

variable "has_external_non_aws_services" {
  type        = bool
  description = "Whether the application(s) in this network need to call external non-AWS services. Determines whether or not to create NAT gateways."
  default     = false
}

variable "nat_gateway_config" {
  # nat gateways are pricey, unless outgoing traffic
  # is part of your service, one should be enough
  # (i.e. to allow your app to fetch some resources on startup)
  type        = string
  default     = "none"
  description = "How many NAT gateways (which can be pricey) to create. None, a single one that is shared across all subnets, one per availability zone, or one per private subnet"
  validation {
    condition     = contains(["none", "shared", "per_az", "per_subnet"], var.nat_gateway_config)
    error_message = "Allowed values for nat_gateway_config are 'none', 'shared', 'per_az', 'per_subnet'"
  }
}
