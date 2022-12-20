"""API that returns direct media links in desired format for youtube URLs.

[========> INFO <========]
Author: v0rap <me@thvxl.se>
License: GPLv3

[=======> USAGE <=======]
API for ytdl.se. Valid routes are:

- METHOD: POST
  URL: $API_BASE/get-media-urls
  BODY: {"url": $YOUTUBE_URL}

Send a query parameter "URL" with the URL to convert

Allowed URL formats are:
- http[s]://www.youtube.com/watch?v=jGT37X3H_MA
- http[s]://youtu.be/jGT37X3H_MA

"""
import logging
from urllib.parse import urlparse
import json
import re
from youtube_dl import YoutubeDL

video_id_regex = re.compile(r"[A-Za-z0-9_\-]{11}")

DOMAINS = {
    "youtube.com": {
        "parser": lambda url: urlparse(url).query.split("=")[-1]
    },
    "youtu.be": {
        "parser": lambda url: urlparse(url).path[-1:]
    }
}

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def generate_response(resp_dict: dict, status_code: int = 200):
    return {
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(resp_dict),
        "statusCode": status_code
    }


def get_media_urls(body):
    url = body.get("url")
    parsed = urlparse(url)
    domain = ".".join(parsed.hostname.split(".")[-2:])
    if domain not in DOMAINS:
        logging.info(f"Invalid DOMAIN for {url=}")
        return generate_response({
            "detail": (
                "Invalid URL domain. "
                f"Allowed domains are: {DOMAINS.keys()}")
            }, status_code=400)

    video_id = DOMAINS[domain]["parser"](url)

    if not video_id_regex.fullmatch(video_id):
        return generate_response({
                "detail": f"Invalid video ID: {video_id}"
            }, status_code=400)

    with YoutubeDL({"skip_download": True}) as ydl:
        info_dict = ydl.extract_info(f"https://youtu.be/{video_id}")
    logging.info(f"{info_dict=}")
    return generate_response({
        "sound_url": info_dict.get("requested_formats")[1].get("url"),
        "video_url": info_dict.get("requested_formats")[0].get("url"),
    })


OPERATIONS = {
    "get-media-urls": get_media_urls
}


def handler(event, context):
    logging.info(f"{event=}")
    operation = OPERATIONS.get(event.get("path").split("/")[-1])
    if not operation:
        return generate_response({"detail": "Operation not found"},
                                 status_code=404)
    if not event["body"]:
        return generate_response({"detail": "Body required"},
                                 status_code=400)

    try:
        return operation(json.loads(event["body"]))
    except json.JSONDecodeError:
        return generate_response({"detail": "Body not valid JSON"},
                                 status_code=400)
