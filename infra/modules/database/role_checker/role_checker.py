import os
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    print(os.environ.get("DB_HOST"))
    print(os.environ.get("DB_PORT"))
    print(os.environ.get("DB_USER"))
    return "Hello, world"
