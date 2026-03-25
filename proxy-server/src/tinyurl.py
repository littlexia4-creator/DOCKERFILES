#!/usr/bin/env python3
"""
TinyURL shortener using the TinyURL API.
Usage: python3 tinyurl.py <url>
ref: https://tinyurl.com/app/dev
"""

import sys
import requests

API_URL = "http://api.tinyurl.com/create"
API_TOKEN = "Cniww1RN4NyBDFPsLnT2MJfPfbxuDo0m3sqLNIjBFtUTLR6ZPts2RoC9tCsR"

def shorten(url: str) -> str:
    """Shorten a URL using TinyURL API."""
    headers = {"Authorization": f"Bearer {API_TOKEN}"}
    data = {
        "url": url,
        "domain": "tinyurl.com",
    }
    response = requests.post(API_URL, json=data, headers=headers, timeout=10)
    response.raise_for_status()
    result = response.json()
    return result["data"]["tiny_url"]


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <url>", file=sys.stderr)
        sys.exit(1)

    original_url = sys.argv[1]
    short_url = shorten(original_url)
    print(short_url)
