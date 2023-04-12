#!/bin/sh

export PGPASSWORD="$(aws rds generate-db-auth-token --hostname $DB_HOST --port $DB_PORT --region $AWS_REGION --username $DB_USER )"

echo "$DB_HOST:$DB_PORT:$DB_NAME:$DB_USER:$DB_PASSWORD" > ~/.pgpass

psql "sslmode=verify-full sslrootcert=full_path_to_ssl_certificate" -c "SELECT 'Connected to db';" > /www/dbhealth

echo "httpd started on port $PORT" && trap "exit 0;" TERM INT; httpd -v -p $PORT -h /www -f & wait
