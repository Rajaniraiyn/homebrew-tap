#!/usr/bin/env python3
"""Prepare a Wacom version bump for review, without approving it."""

import re
import subprocess
from scripts.common import ROOT, apply_patch, fetch

URL = "https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/w/wacom-tablet.rb"
SYNC = ROOT / "scripts/sync/wacom-tablet.py"
PATCH = ROOT / "patches/wacom-tablet.patch"
CASK = ROOT / "Casks/wacom-tablet.rb"

upstream = fetch(URL).decode()
version = re.search(r'^  version "(\d+(?:\.\d+)+(?:-\d+[a-z]?)?)"$', upstream, re.MULTILINE)
checksum = re.search(r'^  sha256 "([0-9a-f]{64})"$', upstream, re.MULTILINE)
if not version or not checksum:
    raise ValueError("Could not find the official Wacom version and checksum")

sync = SYNC.read_text()
old_version = re.search(r'^REVIEWED_VERSION = "([^"]+)"$', sync, re.MULTILINE)
old_checksum = re.search(r'^REVIEWED_SHA256 = "([0-9a-f]{64})"$', sync, re.MULTILINE)
if not old_version or not old_checksum:
    raise ValueError("Could not find the reviewed Wacom pin")
new_version, new_checksum = version.group(1), checksum.group(1)
if (new_version, new_checksum) == (old_version.group(1), old_checksum.group(1)):
    print(f"Wacom {new_version} is already reviewed")
    raise SystemExit(0)

patch = PATCH.read_text()
for old, new in ((old_version.group(1), new_version), (old_checksum.group(1), new_checksum)):
    if patch.count(old) != 1:
        raise ValueError("Could not update the Wacom patch pin")
    patch = patch.replace(old, new, 1)
sync = sync.replace(f'REVIEWED_VERSION = "{old_version.group(1)}"', f'REVIEWED_VERSION = "{new_version}"', 1)
sync = sync.replace(f'REVIEWED_SHA256 = "{old_checksum.group(1)}"', f'REVIEWED_SHA256 = "{new_checksum}"', 1)

try:
    candidate = apply_patch("wacom-tablet", upstream, patch)
except subprocess.CalledProcessError:
    candidate = None

SYNC.write_text(sync)
PATCH.write_text(patch)
if candidate is not None:
    CASK.write_text(candidate)
    print(f"Prepared Wacom {new_version}; installer and removal list still need review")
else:
    print(f"Wacom {new_version} patch conflicts; repair it and regenerate the cask before merging")
