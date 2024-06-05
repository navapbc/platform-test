import json
import logging
import os

import boto3
from pg8000.native import Connection, identifier

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def connect_as_master_user() -> Connection:
    user = os.environ["DB_USER"]
    host = os.environ["DB_HOST"]
    port = os.environ["DB_PORT"]
    database = os.environ["DB_NAME"]
    password = get_master_password()

    logger.info(
        "Connecting to database: user=%s host=%s port=%s database=%s",
        user,
        host,
        port,
        database,
    )
    return Connection(
        user=user,
        host=host,
        port=port,
        database=database,
        password=password,
        ssl_context=True,
    )


def get_master_password() -> str:
    ssm = boto3.client("ssm", region_name=os.environ["AWS_REGION"])
    param_name = os.environ["DB_PASSWORD_PARAM_NAME"]
    logger.info("Fetching password from parameter store:\n%s" % param_name)
    result = json.loads(
        ssm.get_parameter(
            Name=param_name,
            WithDecryption=True,
        )[
            "Parameter"
        ]["Value"]
    )
    return result["password"]


def connect_using_iam(user: str) -> Connection:
    client = boto3.client("rds")
    host = os.environ["DB_HOST"]
    port = os.environ["DB_PORT"]
    database = os.environ["DB_NAME"]
    token = client.generate_db_auth_token(DBHostname=host, Port=port, DBUsername=user)
    logger.info(
        "Connecting to database: user=%s host=%s port=%s database=%s",
        user,
        host,
        port,
        database,
    )
    return Connection(
        user=user,
        host=host,
        port=port,
        database=database,
        password=token,
        ssl_context=True,
    )


def execute(conn: Connection, query: str):
    logger.info(f"{conn.user}> {query}")
    conn.run(query)
