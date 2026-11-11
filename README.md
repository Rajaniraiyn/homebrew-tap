# Personal Homebrew tap

```sh
brew install --cask rajaniraiyn/tap/spotify
brew install --cask rajaniraiyn/tap/wacom-tablet
```

- **Spotify** applies SpotX-Bash, disables automatic updates and enables developer mode. Installation requires a Spotify version supported by the pinned SpotX script.
- **Wacom Tablet** removes the update helper, Wacom Center, display settings, experience program and firmware updater after installing the driver. Its tablet compatibility has not yet been tested.

To remove an app and its settings, use `brew uninstall --cask --zap rajaniraiyn/tap/<cask>`. Zap deletes user data.

Run `python3 scripts/update.py` to sync casks from upstream; Wacom updates require review before changing the pinned version.
