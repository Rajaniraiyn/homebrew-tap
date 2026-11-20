#!/usr/bin/env python3
"""Update Rex channels from their Sparkle feeds."""

import hashlib
import re
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "personal-homebrew-tap"})
    return urllib.request.urlopen(request, timeout=60)


for channel in ("preview", "snapshot"):
    cask = ROOT / f"Casks/rex@{channel}.rb"
    base = f"https://blob.superlogical.com/public/rex-app/{channel}/"
    with fetch(f"{base}appcast.xml") as response:
        item = ET.fromstring(response.read()).find("./channel/item")
    if item is None:
        raise ValueError(f"Rex {channel} feed contains no releases")
    short = item.findtext(f"{SPARKLE}shortVersionString", "")
    build = item.findtext(f"{SPARKLE}version", "")
    if not re.fullmatch(r"\d+(?:\.\d+)+", short) or not re.fullmatch(r"\d+", build):
        raise ValueError(f"Invalid Rex {channel} release version")
    enclosure = item.find("enclosure")
    expected = f"{base}Rex-{short}-{build}.dmg"
    if enclosure is None or enclosure.get("url") != expected:
        raise ValueError(f"Unexpected Rex {channel} release URL")

    content = cask.read_text()
    version = f"{short},{build}"
    match = re.search(r'^  version "([^"]+)"$', content, re.MULTILINE)
    if not match:
        raise ValueError(f"Could not find Rex {channel} cask version")
    if match.group(1) == version:
        print(f"Rex {channel} {version} is current")
        continue

    digest = hashlib.sha256()
    with fetch(expected) as response:
        for chunk in iter(lambda: response.read(1024 * 1024), b""):
            digest.update(chunk)
    content = content[:match.start(1)] + version + content[match.end(1):]
    content, count = re.subn(r'(?m)^  sha256 "[0-9a-f]{64}"$', f'  sha256 "{digest.hexdigest()}"', content)
    if count != 1:
        raise ValueError(f"Could not update Rex {channel} cask checksum")
    cask.write_text(content)
