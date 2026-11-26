#!/usr/bin/env python3
"""Prepare a Wacom version bump for review, without approving it."""

import re
import subprocess
from scripts.common import ROOT, apply_patch, fetch

URL = "https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/w/wacom-tablet.rb"
PATCH = ROOT / "patches/wacom-tablet.patch"
CASK = ROOT / "Casks/wacom-tablet.rb"

upstream = fetch(URL).decode()
version = re.search(r'^  version "(\d+(?:\.\d+)+(?:-\d+[a-z]?)?)"$', upstream, re.MULTILINE)
checksum = re.search(r'^  sha256 "([0-9a-f]{64})"$', upstream, re.MULTILINE)
if not version or not checksum:
    raise ValueError("Could not find the official Wacom version and checksum")

current = CASK.read_text()
old_version = re.search(r'^  version "([^"]+)"$', current, re.MULTILINE)
old_checksum = re.search(r'^  sha256 "([0-9a-f]{64})"$', current, re.MULTILINE)
if not old_version or not old_checksum:
    raise ValueError("Could not find the reviewed Wacom pin")
new_version, new_checksum = version.group(1), checksum.group(1)
if (new_version, new_checksum) == (old_version.group(1), old_checksum.group(1)):
    print(f"Wacom {new_version} is already reviewed")
    raise SystemExit(0)

try:
    candidate = apply_patch("wacom-tablet", upstream, PATCH.read_text())
except subprocess.CalledProcessError as error:
    raise SystemExit("Wacom patch conflicts; repair the patch before preparing this update") from error

CASK.write_text(candidate)
print(f"Prepared Wacom {new_version}; installer and removal list still need review")
