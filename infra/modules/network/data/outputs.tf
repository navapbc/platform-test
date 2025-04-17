output "aws_services_security_group_id" {
  value = data.aws_security_groups.aws_services.ids[0]
}

output "database_subnet_group_name" {
  value = module.interface.database_subnet_group_name
}

output "database_subnet_ids" {
  value = data.aws_subnets.database.ids
}

output "public_subnet_ids" {
  value = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  value = data.aws_subnets.private.ids
}

output "vpc_id" {
  value = data.aws_vpc.network.id
}

data "aws_wafv2_web_acl" "network" {
  count = var.enable_waf ? 1 : 0
  name  = module.interface.waf_acl_name
  scope = "REGIONAL"
}

output "waf_arn" {
  value = var.enable_waf ? one(data.aws_wafv2_web_acl.network[*].arn) : null
}
