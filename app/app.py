import logging
import os
from datetime import datetime

import click
from flask import Flask, redirect, render_template, request

import notifications
import storage
from db import get_db_connection

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = Flask(__name__)


def main():
    host = os.environ.get("HOST")
    port = os.environ.get("PORT")
    logger.info("Running Flask app on host %s and port %s", host, port)
    app.run(host=host, port=port)


@app.route("/")
def hello_world():
    return render_template("index.html")


@app.route("/health")
def health():
    conn = get_db_connection()
    conn.execute("SELECT 1")
    return {
        "status": "healthy",
        "version": os.environ.get("IMAGE_TAG"),
    }


@app.route("/migrations")
def migrations():
    conn = get_db_connection()
    cur = conn.execute("SELECT last_migration_date FROM migrations")
    row = cur.fetchone
    if row is None:
        return "No migrations run"
    else:
        last_migration_date = cur.fetchone()[0]
        return f"Last migration on {last_migration_date}"


@app.route("/document-upload")
def document_upload():
    path = f"uploads/{datetime.now().date()}/${{filename}}"
    upload_url, fields = storage.create_upload_url(path)
    additional_fields = "".join(
        [
            f'<input type="hidden" name="{name}" value="{value}">'
            for name, value in fields.items()
        ]
    )
    # Note: Additional fields should come first before the file and submit button
    return f'<form method="post" action="{upload_url}" enctype="multipart/form-data">{additional_fields}<input type="file" name="file"><input type="submit"></form>'


@app.get("/notifications")
def notifications_get():
    return f'<form method="post">Send test email to:<input type="email" name="to"><input type="submit"></form>'


@app.post("/notifications")
def notifications_post():
    pinpoint_app_id = os.environ["AWS_PINPOINT_APP_ID"]
    sender_email = os.environ["AWS_PINPOINT_SENDER_EMAIL"]
    to = request.form["to"]
    subject = "Test notification"
    message = "This is a system generated test notification. If you received this email in error, please ignore it."
    notifications.send_email(to, subject, message)
    return redirect("/notifications", code=303)


@app.route("/secrets")
def secrets():
    secret_sauce = os.environ["SECRET_SAUCE"]
    random_secret = os.environ["RANDOM_SECRET"]
    return f'The secret sauce is "{secret_sauce}".<br> The random secret is "{random_secret}".'


@app.cli.command("etl", help="Run ETL job")
@click.argument("input")
def etl(input):
    # input should be something like "etl/input/somefile.ext"
    assert input.startswith("etl/input/")
    output = input.replace("/input/", "/output/")
    data = storage.download_file(input)
    storage.upload_file(output, data)


@app.cli.command("cron", help="Run cron job")
def cron():
    conn = get_db_connection()
    conn.execute("SELECT 1")
    print("Hello from cron job")


if __name__ == "__main__":
    main()
