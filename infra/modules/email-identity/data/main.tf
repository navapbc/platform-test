locals {
  # Construct DNS records to be added to the sending domain.
  # Only used if the sender identity verification method is domain verification.
  dkim_dns_verification_records = var.email_verification_method == "domain" ? [
    for token in data.aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens : {
      type  = "CNAME"
      name  = "${token}._domainkey"
      value = "${token}.dkim.amazonses.com"
    }
  ] : []
}

module "interface" {
  source = "../interface"

  sender_email = var.sender_email
}

data "aws_sesv2_email_identity" "sender" {
  email_identity = var.email_verification_method == "email" ? var.sender_email : module.interface.domain
}
