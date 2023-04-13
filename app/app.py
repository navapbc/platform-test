import os

from flask import Flask
import boto3
import psycopg
import psycopg.conninfo

app = Flask(__name__)

def main():
    host = os.environ.get("HOST")
    port = os.environ.get("PORT")
    app.run(host=host, port=port)


@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"


@app.route("/health")
def health():
    return "OK"


@app.route("/dbhealth")
def dbhealth():
    print("dbhealth")
    conn = get_db_connection()
    conn.execute("SELECT 1")
    return "DB OK"


def get_db_token(host, port, user):
    region = os.environ.get("AWS_REGION")

    # gets the credentials from .aws/credentials
    client = boto3.client("rds", region_name=region)

    print("generating token")
    token = client.generate_db_auth_token(DBHostname=host, Port=port, DBUsername=user, Region=region)
    return token


def get_db_connection():
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    user = os.environ.get("DB_USER")
    password = os.environ.get("DB_PASSWORD")
    if password is None:
        password = get_db_token(host, port, user)
    else:
        print("already have token")
    dbname = os.environ.get("DB_NAME")

    print(password)
    conninfo = psycopg.conninfo.make_conninfo(host=host, port=port, user=user, password=password, dbname=dbname)

    conn = psycopg.connect(conninfo)
    return conn


if __name__ == "__main__":
    main()
