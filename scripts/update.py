#!/usr/bin/env python3
"""Run each cask's sync script, optionally selecting cask names."""

import subprocess
import sys
from pathlib import Path

directory = Path(__file__).resolve().parent / "sync"
scripts = {path.stem: path for path in directory.glob("*.py") if not path.name.startswith("_")}
names = sys.argv[1:] or sorted(scripts)
unknown = sorted(set(names) - scripts.keys())
if unknown:
    raise SystemExit(f"Unknown sync scripts: {', '.join(unknown)}")
if not names:
    raise SystemExit("No sync scripts found")

failed = []
for name in names:
    print(f"==> Syncing {name}", flush=True)
    if subprocess.run([sys.executable, str(scripts[name])]).returncode:
        failed.append(name)
if failed:
    raise SystemExit(f"Sync failed: {', '.join(failed)}")
