import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_mp3_url(link):
    pass


OPERATIONS = {
    "get_mp3_url": get_mp3_url
}


def handler(event, context):
    logging.debug(f"{event=}")
    return {
        "headers": {
            "Content-Type": "application/json"
        },
        "body": '{"message": "Hello, world!"}',
        "statusCode": 200
    }
