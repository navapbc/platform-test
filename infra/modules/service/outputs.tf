output "public_endpoint" {
  description = "The public endpoint for the service."
  value       = "http://${aws_lb.alb.dns_name}"
}

output "app_security_group_id" {
  description = "The ID of the security group for the application layer."
  value       = aws_security_group.app.id
}
