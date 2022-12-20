import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logging.info("Function was triggered!")
    return {
        "message": "Hello world!"
    }
