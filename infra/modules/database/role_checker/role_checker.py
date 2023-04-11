import os
import logging
import psycopg

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    print(os.environ.get("DB_HOST"))
    print(os.environ.get("DB_PORT"))
    print(os.environ.get("DB_USER"))
    print(psycopg)
    return "Hello, world"
