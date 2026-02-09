resource "aws_cloudformation_stack" "sms_config_set" {
  name = "${var.name}-sms-config-set"

  template_body = jsonencode({
    Resources = {
      SmsConfigSet = {
        Type = "AWS::SMSVOICE::ConfigurationSet"
        Properties = {
          ConfigurationSetName = "${var.name}-sms-config-set"
          EventDestinations = [
            {
              EventDestinationName = "sms-event-destination"
              Enabled              = true
              MatchingEventTypes   = ["TEXT_ALL"]
              CloudWatchLogsDestination = {
                IamRoleArn  = aws_iam_role.logging_role.arn
                LogGroupArn = aws_cloudwatch_log_group.sms_logs.arn
              }
            }
          ]
        }
      }
    }
    Outputs = {
      # The 'Ref' of a ConfigurationSet returns its Name
      ConfigSetName = {
        Value = { "Ref" : "SmsConfigSet" }
      }
      # Construct the ARN manually using standard AWS ARN format
      ConfigSetArn = {
        Value = {
          "Fn::Sub" : "arn:aws:sms-voice:$${AWS::Region}:$${AWS::AccountId}:configuration-set/$${SmsConfigSet}"
        }
      }
    }
  })
}

resource "aws_pinpointsmsvoicev2_opt_out_list" "sms_opt_out_list" {
  count = var.enable_opt_out_list ? 1 : 0
  name  = "${var.name}-sms-opt-out-list"
}

resource "aws_cloudwatch_log_group" "sms_logs" {
  name              = "/aws/sms-voice/${var.name}/sms-notifications/delivery-receipts"
  retention_in_days = 30
}