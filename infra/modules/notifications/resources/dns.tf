data "aws_route53_zone" "zone" {
  name = var.domain_name
}

# DNS records for email identity verification if email_verification_method is "domain"
resource "aws_route53_record" "dkim" {
  count = var.email_verification_method == "domain" ? 3 : 0

  allow_overwrite = true
  ttl             = 60
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.zone.zone_id
  name            = "${aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens[count.index]}._domainkey"
  records         = ["${aws_sesv2_email_identity.sender.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]

  depends_on = [aws_sesv2_email_identity.sender]
}

resource "aws_route53_record" "spf_mail_from" {
  count = var.email_verification_method == "domain" ? 1 : 0

  allow_overwrite = true
  ttl             = "600"
  type            = "TXT"
  zone_id         = data.aws_route53_zone.zone.zone_id
  name            = aws_sesv2_email_identity_mail_from_attributes.sender.mail_from_domain
  records         = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "mx_send_mail_from" {
  count = var.email_verification_method == "domain" ? 1 : 0

  allow_overwrite = true
  type            = "MX"
  ttl             = "600"
  zone_id         = data.aws_route53_zone.zone.zone_id
  name            = aws_sesv2_email_identity_mail_from_attributes.sender.mail_from_domain
  records         = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

resource "aws_route53_record" "mx_receive" {
  count = var.email_verification_method == "domain" ? 1 : 0

  allow_overwrite = true
  type            = "MX"
  ttl             = "600"
  name            = local.mail_from_domain
  zone_id         = data.aws_route53_zone.zone.zone_id
  records         = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}
