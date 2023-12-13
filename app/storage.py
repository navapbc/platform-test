import os

import boto3


def create_upload_url(path):
    bucket_name = os.environ.get("BUCKET")

    s3_client = boto3.client("s3")
    response = s3_client.generate_presigned_post(bucket_name, path)
    return response["url"]
