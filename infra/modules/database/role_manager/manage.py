import itertools
import os
from operator import itemgetter

from pg8000.native import Connection, identifier

import db


def manage():
    """Manage database roles, schema, and privileges"""

    print("Running command 'manage' to manage database roles, schema, and privileges")
    conn = db.connect_as_master_user()

    print("Current database configuration")
    print_roles(get_roles(conn))
    print_schema_privileges(get_schema_privileges(conn))

    print("Configuring database")
    configure_database(conn)

    print("New database configuration")

    new_roles = get_roles(conn)
    print_roles(new_roles)

    new_schema_privileges = get_schema_privileges(conn)
    print_schema_privileges(new_schema_privileges)

    return {
        "roles": new_roles,
        "roles_with_groups": get_roles_with_groups(conn),
        "schema_privileges": {
            schema_name: schema_acl for schema_name, schema_acl in new_schema_privileges
        },
    }


def get_roles(conn: Connection) -> list[str]:
    return [
        row[0]
        for row in db.execute(
            conn,
            "SELECT rolname "
            "FROM pg_roles "
            "WHERE rolname NOT LIKE 'pg_%' "
            "AND rolname NOT LIKE 'rds%'",
        )
    ]


def get_roles_with_groups(conn: Connection) -> dict[str, str]:
    roles_groups = db.execute(
        conn,
        """
        SELECT u.rolname AS user, g.rolname AS group
        FROM pg_roles u
        INNER JOIN pg_auth_members a ON u.oid = a.member
        INNER JOIN pg_roles g ON g.oid = a.roleid
        ORDER BY user ASC
        """,
    )

    result = {}
    for user, groups in itertools.groupby(roles_groups, itemgetter(0)):
        result[user] = ",".join(map(itemgetter(1), groups))
    return result


# Get schema access control lists. The format of the ACLs is abbreviated. To interpret
# what the ACLs mean, see the Postgres documentation on Privileges:
# https://www.postgresql.org/docs/current/ddl-priv.html
def get_schema_privileges(conn: Connection) -> list[tuple[str, str]]:
    return [
        (row[0], row[1])
        for row in db.execute(
            conn,
            """
            SELECT nspname, nspacl
            FROM pg_namespace
            WHERE nspname NOT LIKE 'pg_%'
            AND nspname <> 'information_schema'
            """,
        )
    ]


def configure_database(conn: Connection) -> None:
    print("-- Configuring database")
    app_username = os.environ.get("APP_USER")
    migrator_username = os.environ.get("MIGRATOR_USER")
    schema_name = os.environ.get("DB_SCHEMA")
    database_name = os.environ.get("DB_NAME")

    print("---- Revoking default access on public schema")
    db.execute(conn, "REVOKE CREATE ON SCHEMA public FROM PUBLIC")
    print("---- Revoking database access from public role")
    db.execute(conn, f"REVOKE ALL ON DATABASE {identifier(database_name)} FROM PUBLIC")
    print("---- Setting default search path to schema=%s", schema_name)
    db.execute(
        conn,
        f"ALTER DATABASE {identifier(database_name)} SET search_path TO {identifier(schema_name)}",
    )

    configure_roles(conn, [migrator_username, app_username], database_name)
    configure_schema(conn, schema_name, migrator_username, app_username)


def configure_roles(conn: Connection, roles: list[str], database_name: str) -> None:
    print("---- Configuring roles")
    for role in roles:
        configure_role(conn, role, database_name)


def configure_role(conn: Connection, username: str, database_name: str) -> None:
    print("------ Configuring role: username=%s", username)
    role = "rds_iam"
    db.execute(
        conn,
        f"""
        DO $$
        BEGIN
            CREATE USER {identifier(username)};
            EXCEPTION WHEN DUPLICATE_OBJECT THEN
            RAISE NOTICE 'user already exists';
        END
        $$;
        """,
    )
    db.execute(conn, f"GRANT {identifier(role)} TO {identifier(username)}")
    db.execute(
        conn,
        f"GRANT CONNECT ON DATABASE {identifier(database_name)} TO {identifier(username)}",
    )


def configure_schema(
    conn: Connection, schema_name: str, migrator_username: str, app_username: str
) -> None:
    print("---- Configuring schema")
    print("------ Creating schema: schema_name=%s", schema_name)
    db.execute(conn, f"CREATE SCHEMA IF NOT EXISTS {identifier(schema_name)}")
    print(
        "------ Changing schema owner: schema_name=%s owner=%s",
        schema_name,
        migrator_username,
    )
    db.execute(
        conn,
        f"ALTER SCHEMA {identifier(schema_name)} OWNER TO {identifier(migrator_username)}",
    )
    print(
        "------ Granting schema usage privileges: schema_name=%s role=%s",
        schema_name,
        app_username,
    )
    db.execute(
        conn,
        f"GRANT USAGE ON SCHEMA {identifier(schema_name)} TO {identifier(app_username)}",
    )


def print_roles(roles: list[str]) -> None:
    print("Roles")
    for role in roles:
        print(f"Role info: name={role}")


def print_schema_privileges(schema_privileges: list[tuple[str, str]]) -> None:
    print("Schema privileges")
    for schema_name, schema_acl in schema_privileges:
        print(f"Schema info: name={schema_name} acl={schema_acl}")
