"""Run all sync plugins, or selected cask names."""

import subprocess
import sys

from scripts.common import ROOT, plugins

available = plugins("sync")
names = sys.argv[1:] or available
unknown = sorted(set(names) - set(available))
if unknown:
    raise SystemExit(f"Unknown sync scripts: {', '.join(unknown)}")
if not names:
    raise SystemExit("No sync scripts found")

failed = []
for name in names:
    print(f"==> Syncing {name}", flush=True)
    if subprocess.run([sys.executable, "-B", "-m", f"scripts.sync.{name}"], cwd=ROOT).returncode:
        failed.append(name)
if failed:
    raise SystemExit(f"Sync failed: {', '.join(failed)}")
