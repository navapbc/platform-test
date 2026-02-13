# This module manages AWS End User Messaging SMS resources, including configuration set and phone number management.
# The module also sets up a CloudWatch Log Group for SMS delivery receipts and an IAM role with permissions to
# write to that log group. It supports optional registration of a specific phone number or the use of a simulator
# phone number. It creates an SMS Phone Number Pool and associates the phone number with that pool.
# It outputs the SMS Phone Number Pool ARN and ID for use in the application environment variables.
# It sets the SMS IAM policy to allow sending messages using the configuration set, and restricts it to allow
# SendMessage by the SMS Phone Pool. The configuration set is configured to log all SMS events to CloudWatch Logs
# using the created IAM role.

data "aws_region" "current" {}
locals {
  phone_number_arn_base = (
    "arn:aws:sms-voice:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:phone-number"
  )
  registration_id_arn = var.sms_sender_phone_number_registration_id != null ? "${local.phone_number_arn_base}/${var.sms_sender_phone_number_registration_id}" : null
  simulator_id_arn    = var.sms_simulator_phone_number_id != null ? "${local.phone_number_arn_base}/${var.sms_simulator_phone_number_id}" : null

  mandatory_keywords = {
    STOP = {
      Message = "Reply STOP to unsubscribe"
    }
    HELP = {
      Message = "Reply HELP for help"
    }
  }

  phone_number_base_properties = {
    IsoCountryCode     = "US"
    NumberCapabilities = ["SMS"]
    MandatoryKeywords  = local.mandatory_keywords
  }
}
resource "aws_cloudformation_stack" "sms_config_set" {
  name = "${var.name}-config-set"

  template_body = jsonencode({
    Resources = merge(
      {
        SmsConfigSet = {
          Type = "AWS::SMSVOICE::ConfigurationSet"
          Properties = {
            ConfigurationSetName = "${var.name}-config-set"
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
        SmsPhonePool = {
          Type = "AWS::SMSVOICE::Pool"
          Properties = {
            OriginationIdentities = var.sms_sender_phone_number_registration_id != null ? [
              local.registration_id_arn
              ] : var.sms_simulator_phone_number_id != null ? [
              local.simulator_id_arn
            ] : []
            MandatoryKeywords = local.mandatory_keywords
          }
        }
      },
      (var.sms_sender_phone_number_registration_id != null || var.sms_simulator_phone_number_id != null) ? {
        SmsPhoneNumber = {
          Type = "AWS::SMSVOICE::PhoneNumber"
          Properties = merge(
            local.phone_number_base_properties,
            var.sms_sender_phone_number_registration_id != null ? {
              # Use registration ID if provided (takes priority)
              RegistrationId = var.sms_sender_phone_number_registration_id
              NumberType     = var.sms_number_type
              } : {
              # Use simulator phone number ID - reference existing phone number
              PhoneNumberId = var.sms_simulator_phone_number_id
              NumberType    = "SIMULATOR"
            }
          )
        }
      } : {}
    )
    Outputs = merge(
      {
        ConfigSetName = {
          Value = { "Ref" : "SmsConfigSet" }
        }
        ConfigSetArn = {
          Value = {
            "Fn::Sub" : "arn:aws:sms-voice:$${AWS::Region}:$${AWS::AccountId}:configuration-set/$${SmsConfigSet}"
          }
        }
        PhonePoolId = {
          Value = { "Ref" : "SmsPhonePool" }
        }
        PhonePoolArn = {
          Value = {
            "Fn::Sub" : "arn:aws:sms-voice:$${AWS::Region}:$${AWS::AccountId}:pool/$${SmsPhonePool}"
          }
        }
      },
      (var.sms_sender_phone_number_registration_id != null || var.sms_simulator_phone_number_id != null) ? {
        # The phone number ID (only if created)
        PhoneNumberId = {
          Value = { "Ref" : "SmsPhoneNumber" }
        }
        # Construct phone number ARN
        PhoneNumberArn = {
          Value = {
            "Fn::Sub" : "arn:aws:sms-voice:$${AWS::Region}:$${AWS::AccountId}:phone-number/$${SmsPhoneNumber}"
          }
        }
      } : {}
    )
  })
}

resource "aws_cloudwatch_log_group" "sms_logs" {
  name              = "/aws/sms-voice/${var.name}/sms-notifications/delivery-receipts"
  retention_in_days = 30

  # TODO(https://github.com/navapbc/template-infra/issues/164) Encrypt with customer managed KMS key
  # checkov:skip=CKV_AWS_158:Encrypt service logs with customer key in future work
}