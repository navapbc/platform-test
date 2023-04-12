import os
import logging
import pg8000.native

logger = logging.getLogger()
logger.setLevel(logging.INFO)

Connection = pg8000.native.Connection

def lambda_handler(event, context):
    conn = connect()

    print("Current database configuration")

    prev_roles = get_roles(conn)
    print_roles(prev_roles)

    prev_schema_privileges = get_schema_privileges(conn)
    print_schema_privileges(prev_schema_privileges)

    print("Configuring database")
    configure_database(conn)

    print("New database configuration")

    new_roles = get_roles(conn)
    print_roles(new_roles)

    new_schema_privileges = get_schema_privileges(conn)
    print_schema_privileges(new_schema_privileges)

    return {
        "roles": new_roles,
        "schema_privileges": new_schema_privileges,
    }

def connect() -> Connection:
    user = os.environ.get("DB_USER")
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    password = os.environ.get("DB_PASSWORD")

    logger.info("Connecting to database: user=%s host=%s port=%s", user, host, port)
    return Connection(user=user, host=host, port=port, password=password)


def get_roles(conn: pg8000.native.Connection) -> list[str]:
    return [row[0] for row in conn.run("SELECT rolname \
                                       FROM pg_roles \
                                       WHERE rolname NOT LIKE 'pg_%'\
                                       AND rolname NOT LIKE 'rds%'")]


# Get schema access control lists. The format of the ACLs is abbreviated. To interpret
# what the ACLs mean, see the Postgres documentation on Privileges:
# https://www.postgresql.org/docs/current/ddl-priv.html
def get_schema_privileges(conn: Connection) -> list[tuple[str, str]]:
    return [(row[0], row[1]) for row in conn.run("SELECT nspname, nspacl \
                                                 FROM pg_namespace \
                                                 WHERE nspname NOT LIKE 'pg_%' \
                                                 AND nspname <> 'information_schema'")]


def configure_database(conn: Connection) -> None:
    configure_roles(conn)
    configure_schema(conn)


def configure_roles(conn: Connection) -> None:
    app_username = os.environ.get("APP_USER")
    migrator_username = os.environ.get("MIGRATOR_USER")
    configure_role(conn, app_username)
    configure_role(conn, migrator_username)


def configure_role(conn: Connection, username: str) -> None:
    role = "rds_iam"
    conn.run(
        f"""
        DO $$
        BEGIN
            CREATE USER {username} WITH ROLE {role};
            EXCEPTION WHEN DUPLICATE_OBJECT THEN
            RAISE NOTICE 'not creating user {username} -- it already exists';
        END
        $$;
        """
    )


def configure_schema(conn: Connection) -> None:
    schema_name = os.environ.get("SCHEMA_NAME")
    migrator_username = os.environ.get("MIGRATOR_USER")
    conn.run(f"CREATE SCHEMA IF NOT EXISTS {schema_name} AUTHORIZATION {migrator_username}")


def print_roles(roles: list[str]) -> None:
    print("Roles")
    for role in roles:
        print(f"Role info: name={role}")


def print_schema_privileges(schema_privileges: list[tuple[str, str]]) -> None:
    print("Schema privileges")
    for schema_name, schema_acl in schema_privileges:
        print(f"Schema info: name={schema_name} acl={schema_acl}")
