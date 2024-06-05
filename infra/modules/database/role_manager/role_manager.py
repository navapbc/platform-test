import logging

from check import check
from manage import manage


logging.getLogger().setLevel(logging.INFO)


def lambda_handler(event, context):
    if event == "check":
        return check()
    else:
        return manage()
