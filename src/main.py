import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logging.info("Function was triggered!")
    return {
        "headers": {
            "Content-Type": "application/json"
        },
        "body": '{"message": "Hello, world!"}',
        "statusCode": 200
    }
