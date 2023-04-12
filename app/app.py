import os

from flask import Flask
import boto3
from pg8000.native import Connection

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

@app.route("/health")
def health():
    return "OK"

@app.route("/dbhealth")
def dbhealth():
    conn = get_db_connection()
    conn.run("SELECT 1")
    return "OK"


def get_db_token(host, port, user):
    region = os.environ.get("AWS_REGION")

    # gets the credentials from .aws/credentials
    session = boto3.Session(profile_name='default')
    client = session.client('rds')

    token = client.generate_db_auth_token(DBHostname=host, Port=port, DBUsername=user, Region=region)
    return token


def get_db_connection():
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    user = os.environ.get("DB_USER")
    password = get_db_token(host, port, user)
    dbname = os.environ.get("DB_NAME")

    conn = Connection(host=host, port=port, user=user, password=password, database=dbname)
    return conn
