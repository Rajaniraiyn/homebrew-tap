#!/usr/bin/env python3
"""Sync the reviewed Wacom installer and local cask patch."""

import re
import subprocess
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
URL = "https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/w/wacom-tablet.rb"
REVIEWED_VERSION = "6.4.15-2"
REVIEWED_SHA256 = "84af01a189e7416b01c2f37c51e3f47ae16de60b6211bfc6cdd190d2567c90c0"

request = urllib.request.Request(URL, headers={"User-Agent": "personal-homebrew-tap"})
with urllib.request.urlopen(request, timeout=30) as response:
    upstream = response.read().decode()
version = re.search(r'^  version "([^"]+)"$', upstream, re.MULTILINE)
if not version:
    raise ValueError("Could not find the Wacom cask version")
if version.group(1) != REVIEWED_VERSION:
    print(f"Wacom {version.group(1)} needs removal-list review; keeping {REVIEWED_VERSION}")
    raise SystemExit(0)
if f'  sha256 "{REVIEWED_SHA256}"' not in upstream:
    raise ValueError("The Wacom installer checksum changed; review it before syncing")

with tempfile.TemporaryDirectory() as directory:
    target = Path(directory) / "wacom-tablet.rb"
    target.write_text(upstream)
    subprocess.run(
        ["patch", "-t", "-N", "-F", "0", "-p1", "-i", str(ROOT / "patches/wacom-tablet.patch")],
        cwd=directory,
        check=True,
    )
    (ROOT / "Casks/wacom-tablet.rb").write_text(target.read_text())
