# Create the AWS Pinpoint application.
resource "aws_pinpoint_app" "app" {
  name = var.name
}
