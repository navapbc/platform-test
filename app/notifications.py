import os
import boto3

def send_email(to: str, subject: str, message: str):
    ses_client = boto3.client("ses", region_name=os.environ.get("AWS_SES_REGION"))
    sender_email = os.environ["AWS_SES_SENDER_EMAIL"]

    response = ses_client.send_email(
        Source=sender_email,
        Destination={
            'ToAddresses': [to]
        },
        Message={
            'Subject': {
                'Charset': 'UTF-8',
                'Data': subject
            },
            'Body': {
                'Html': {
                    'Charset': 'UTF-8',
                    'Data': message
                },
                'Text': {
                    'Charset': 'UTF-8',
                    'Data': message
                }
            }
        }
    )
    print(response)

    return response
