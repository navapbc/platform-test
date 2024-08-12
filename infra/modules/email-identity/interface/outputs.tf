output "domain" {
  description = "Extract the domain used for sender identity verification from the sender_email"
  value       = regex("@(.*)", var.sender_email)[0]
}
