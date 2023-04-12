import os
import logging
import pg8000.native

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def connect() -> pg8000.native.Connection:
    user = os.environ.get("DB_USER")
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    password = os.environ.get("DB_PASSWORD")

    logger.info("Connecting to database: user=%s host=%s port=%s", user, host, port)
    return pg8000.native.Connection(user=user, host=host, port=port, password=password)

def get_roles(conn: pg8000.native.Connection) -> list[str]:
    return [row[0] for row in conn.run("SELECT rolname \
                                       FROM pg_roles \
                                       WHERE rolname NOT LIKE 'pg_%'\
                                       AND rolname NOT LIKE 'rds%'")]

# Get schema access control lists. The format of the ACLs is abbreviated. To interpret
# what the ACLs mean, see the Postgres documentation on Privileges:
# https://www.postgresql.org/docs/current/ddl-priv.html
def get_schema_privileges(conn: pg8000.native.Connection) -> list[tuple[str, str]]:
    return [(row[0], row[1]) for row in conn.run("SELECT nspname, nspacl \
                                                 FROM pg_namespace \
                                                 WHERE nspname NOT LIKE 'pg_%' \
                                                 AND nspname <> 'information_schema'")]

def lambda_handler(event, context):
    conn = connect()
    roles = get_roles(conn)
    for role in roles:
        logger.info("Role info: name=%s", role)
    schema_privileges = get_schema_privileges(conn)
    for schema_name, schema_acl in schema_privileges:
        logger.info("Schema info: name=%s acl=%s", schema_name, schema_acl)
    return {
        "roles": roles,
        "schema_privileges": schema_privileges,
    }
