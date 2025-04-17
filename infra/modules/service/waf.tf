resource "aws_wafv2_web_acl_association" "main" {
  count        = var.waf_arn != null ? 1 : 0
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = var.waf_arn
}
