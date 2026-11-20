# Personal Homebrew tap

```sh
brew install --cask rajaniraiyn/tap/spotify
brew install --cask rajaniraiyn/tap/wacom-tablet
brew install --cask rajaniraiyn/tap/rex@preview
# Or: brew install --cask rajaniraiyn/tap/rex@snapshot
```

- **Spotify** applies SpotX-Bash, disables automatic updates and enables developer mode. Installation requires a Spotify version supported by the pinned SpotX script.
- **Wacom Tablet** removes the update helper, Wacom Center, display settings, experience program and firmware updater after installing the driver. Its tablet compatibility has not yet been tested.
- **Rex** offers mutually exclusive preview and snapshot builds. Both can update themselves; use `brew upgrade --greedy` to include them in Homebrew upgrades.

To remove an app and its settings, use `brew uninstall --cask --zap rajaniraiyn/tap/<cask>`. Zap deletes user data. For Rex, it stops local Rex servers and deletes their saved state and configuration; active sessions will end.

Run `python3 -B -m scripts.sync` to sync casks from upstream. New Wacom versions get a review pull request; other casks continue syncing independently.

Add automatic syncs under `scripts/sync/` and review candidates under `scripts/review/`. Both can use `scripts/common.py` and run as Python modules. Review scripts use one persistent pull request per cask; an optional matching `.md` file supplies review instructions.
