import logging

from check import check
from manage import manage


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    if event == "check":
        return check()
    else:
        return manage()
