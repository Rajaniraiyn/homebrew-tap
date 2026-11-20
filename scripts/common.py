"""Shared helpers for cask sync and review scripts."""

import re
import subprocess
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def plugins(group):
    return sorted(
        path.stem for path in (ROOT / "scripts" / group).glob("*.py")
        if re.fullmatch(r"[a-z0-9][a-z0-9@+-]*", path.stem)
    )


def open_url(url, *, timeout=30):
    request = urllib.request.Request(url, headers={"User-Agent": "personal-homebrew-tap"})
    return urllib.request.urlopen(request, timeout=timeout)


def fetch(url, *, timeout=30):
    with open_url(url, timeout=timeout) as response:
        return response.read()


def apply_patch(name, source, patch):
    with tempfile.TemporaryDirectory() as directory:
        target = Path(directory) / f"{name}.rb"
        patch_file = Path(directory) / f"{name}.patch"
        target.write_text(source)
        patch_file.write_text(patch)
        subprocess.run(
            ["patch", "-t", "-N", "-F", "0", "-p1", "-i", str(patch_file)],
            cwd=directory,
            check=True,
        )
        return target.read_text()
