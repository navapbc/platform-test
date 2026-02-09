import logging
import os
import boto3
import json
from botocore.exceptions import ClientError

logger = logging.getLogger()

def send_sms(sender_number, phone_number, message, message_type="TRANSACTIONAL"):
    """
    Send SMS via AWS End User Messaging (PinpointSMSVoiceV2)
    """
    try:
        logger.info("Initializing AWS Pinpoint SMS Voice V2 client")
        client = boto3.client("pinpoint-sms-voice-v2")
        #sender_number = os.environ["AWS_SMS_SENDER_PHONE_NUMBER"]
        configuration_set = os.environ.get("AWS_SMS_CONFIGURATION_SET_NAME")
        logger.info("Using Configuration Set: %s", configuration_set)

        params = {
            "DestinationPhoneNumber": phone_number,
            "OriginationIdentity": sender_number,
            "MessageBody": message,
            "MessageType": message_type
        }

        # Add configuration set for tracking
        if configuration_set:
            params["ConfigurationSetName"] = configuration_set

        # Add context for tracking (optional)
        params["Context"] = {
            "ApplicationName": "template-app",
            "Environment": "dev"
        }

        response = client.send_text_message(**params)

        return {
            "success": True,
            "message_id": response.get("MessageId"),
            "response": response
        }

    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        error_message = e.response["Error"]["Message"]
        logger.error(f"ClientError: {error_code} - {error_message}")

        return {
            "success": False,
            "error": error_message,
            "error_code": error_code,
            "details": str(e)
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

def check_opt_out_status(phone_number):
    """
    Check if a phone number is opted out
    """
    try:
        client = boto3.client("pinpoint-sms-voice-v2")
        opt_out_list = os.environ.get("AWS_SMS_OPT_OUT_LIST")

        if not opt_out_list:
            return {"opted_out": False, "error": "No opt-out list configured"}

        response = client.describe_opted_out_numbers(
            OptOutListName=opt_out_list,
            OptedOutNumbers=[phone_number]
        )

        opted_out_numbers = response.get("OptedOutNumbers", [])
        is_opted_out = any(num["OptedOutNumber"] == phone_number for num in opted_out_numbers)

        return {"opted_out": is_opted_out}

    except Exception as e:
        return {"error": str(e)}

def get_sms_spending_limits():
    """
    Get current SMS spending limits
    """
    try:
        client = boto3.client("pinpoint-sms-voice-v2")
        response = client.describe_spend_limits()

        return {
            "success": True,
            "spend_limits": response.get("SpendLimits", [])
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }