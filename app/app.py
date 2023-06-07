import os

from flask import Flask
import boto3
import logging
import psycopg
import psycopg.conninfo

logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = Flask(__name__)

def main():
    host = os.environ.get("HOST")
    port = os.environ.get("PORT")
    logger.info(f"Running Flask app on host {host} and port {port}")
    print(f"Running Flask app on host {host} and port {port}")
    app.run(host=host, port=port)


@app.route("/")
def hello_world():
    conn = get_db_connection()
    conn.execute("SELECT 1")
    return "<p>Hello, World!</p>"


@app.route("/health")
def health():
    return "OK"


def get_db_token(host, port, user):
    region = os.environ.get("AWS_REGION")

    # gets the credentials from .aws/credentials
    logger.info(f"Getting RDS client for region {region}")
    print(f"Getting RDS client for region {region}")
    client = boto3.client("rds", region_name=region)

    logger.info(f"Generating auth token for user {user}")
    print(f"Generating auth token for user {user}")
    token = client.generate_db_auth_token(DBHostname=host, Port=port, DBUsername=user, Region=region)
    return token


def get_db_connection():
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    user = os.environ.get("DB_USER")
    password = get_db_token(host, port, user)
    dbname = os.environ.get("DB_NAME")

    conninfo = psycopg.conninfo.make_conninfo(host=host, port=port, user=user, password=password, dbname=dbname)

    conn = psycopg.connect(conninfo)
    return conn


if __name__ == "__main__":
    main()
