"""Discover review plugins, run one, or print its review instructions."""

import argparse
import json
import subprocess
import sys

from scripts.common import ROOT, plugins

parser = argparse.ArgumentParser()
parser.add_argument("name", nargs="?")
mode = parser.add_mutually_exclusive_group()
mode.add_argument("--list", action="store_true")
mode.add_argument("--instructions", action="store_true")
args = parser.parse_args()

available = plugins("review")
if args.list:
    if args.name:
        parser.error("--list does not accept a cask name")
    print(json.dumps(available))
elif args.name not in available:
    parser.error("specify an existing review plugin")
elif args.instructions:
    path = ROOT / "scripts" / "review" / f"{args.name}.md"
    print(path.read_text() if path.is_file() else "Review and test this candidate before merging.")
else:
    raise SystemExit(subprocess.run([sys.executable, "-B", "-m", f"scripts.review.{args.name}"], cwd=ROOT).returncode)
