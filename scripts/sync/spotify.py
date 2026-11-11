#!/usr/bin/env python3
"""Apply the local patch to the matching upstream Spotify cask."""

import hashlib
import json
import re
import subprocess
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPOTIFY = "https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/s/spotify.rb"
API = "https://api.github.com/repos/SpotX-Official/SpotX-Bash/commits/main"
RAW = "https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/{}/spotx.sh"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "personal-homebrew-tap"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


commit = json.loads(fetch(API))["sha"]
if not re.fullmatch(r"[0-9a-f]{40}", commit):
    raise ValueError("Invalid upstream commit")
script = fetch(RAW.format(commit))
build_match = re.search(rb'^buildVer="(([0-9]+(?:\.[0-9]+){3})\.g[0-9a-f]+)"$', script, re.MULTILINE)
if not build_match:
    raise ValueError("Could not find SpotX's supported Spotify version")
build, supported = (part.decode() for part in build_match.groups())
upstream = fetch(SPOTIFY).decode()
version = re.search(r'^  version "([0-9]+(?:\.[0-9]+){3})"$', upstream, re.MULTILINE)
if not version:
    raise ValueError("Could not find the official Spotify cask version")
if version.group(1) != supported:
    print(f"Waiting: Spotify {version.group(1)}, SpotX supports {supported}")
    raise SystemExit(0)

upstream = upstream[:version.start(1)] + "@SPOTIFY_VERSION@" + upstream[version.end(1):]
with tempfile.TemporaryDirectory() as directory:
    target = Path(directory) / "spotify.rb"
    target.write_text(upstream)
    subprocess.run(
        ["patch", "-t", "-N", "-F", "0", "-p1", "-i", str(ROOT / "patches/spotify.patch")],
        cwd=directory,
        check=True,
    )
    result = target.read_text()

for key, value in {
    "@SPOTIFY_VERSION@": supported,
    "@COMMIT@": commit,
    "@BUILD@": build,
    "@CHECKSUM@": hashlib.sha256(script).hexdigest(),
}.items():
    if result.count(key) != 1:
        raise ValueError(f"Unexpected patch placeholder: {key}")
    result = result.replace(key, value)
(ROOT / "Casks/spotify.rb").write_text(result)
