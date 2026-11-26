# Personal Homebrew tap

```sh
brew install --cask rajaniraiyn/tap/spotify
brew install --cask rajaniraiyn/tap/wacom-tablet
brew install --cask rajaniraiyn/tap/edits
brew install --cask rajaniraiyn/tap/rex@preview
# Or: brew install --cask rajaniraiyn/tap/rex@snapshot
```

- **Spotify** applies SpotX-Bash, disables automatic updates and enables developer mode. Installation requires a Spotify version supported by the pinned SpotX script.
- **Wacom Tablet** removes the update helper, Wacom Center, display settings, experience program and firmware updater after installing the driver. Its tablet compatibility has not yet been tested.
- **Rex** offers mutually exclusive preview and snapshot builds. Both install the current release from their channel's Sparkle feed and can update themselves.
- **Edits** is Instagram's video editor for Apple silicon Macs running macOS 15.1 or later. It updates itself; use `brew upgrade --greedy` to include it in Homebrew upgrades. The public Sparkle feed currently provides one release channel. Zap removes local projects and settings in Edits' containers, while preserving Meta's shared containers.

To remove an app and its settings, use `brew uninstall --cask --zap rajaniraiyn/tap/<cask>`. Zap deletes user data. For Rex, it stops local Rex servers and deletes their saved state and configuration; active sessions will end.

Edits and Rex use rolling downloads (`version :latest`, `sha256 :no_check`). The shared strategy in `lib/sparkle_download_strategy.rb` uses Homebrew's Sparkle reader to select a compatible release, then lets Homebrew download and extract its archive. It supports archive formats handled by Homebrew and has no app-specific domains or filename patterns. Loading cask metadata makes no network requests.

Each app's small strategy subclass pins its `SUPublicEDKey`, taken from the installed app's `Contents/Info.plist`. Every downloaded or reused archive must match the feed's size and Ed25519 signature before extraction; a failed archive is removed from the cache. Rex also requires a valid signature covering its entire feed, matching its `SURequireSignedFeed` setting. Signing-key changes require a reviewed update to the app's subclass.

The resolver caches by feed, release and archive signature, so expiring URLs do not invalidate downloads and a re-signed build gets a separate cache entry. It reports the SHA-256 of authenticated archives; Homebrew also retains its normal SHA-256 tracking for rolling upgrades. A static `sha256` stanza would require pinning a particular installer. Calculating a hash from an unverified download alone would not authenticate it.

Homebrew's "No checksum defined" message refers to its static checksum check; the resolver's signature verification still runs. New apps configure their trusted key in a subclass, with optional `CHANNELS` and `REQUIRE_SIGNED_FEED` settings.

Let those apps update themselves, or use `brew upgrade --greedy` to include rolling casks. Homebrew checks rolling downloads by comparing installer hashes, which can require a download even to check for updates.

Automation runs weekly on Mondays at 07:17 UTC and can also be started with GitHub Actions' **Run workflow**:

- **Spotify** syncs only when the upstream cask matches SpotX's supported version. Its runtime version check and pinned SpotX script prevent incompatible patching. Run `python3 -B -m scripts.sync` locally to refresh it without waiting for automation.
- **Wacom Tablet** gets a review pull request when the upstream installer changes. The committed cask holds the reviewed version and checksum; its local patch is applied when preparing the candidate. Run `python3 -B -m scripts.review wacom-tablet` locally to prepare one. Its component removal list still needs review before merging.

Add automatic syncs under `scripts/sync/` and review candidates under `scripts/review/`. Both can use `scripts/common.py` and run as Python modules. Review scripts use one persistent pull request per cask; an optional matching `.md` file supplies review instructions.

Upstream Spotify and Wacom casks are extended through checked-in patches during maintenance, so installation uses reviewed local definitions. Avoid fetching and evaluating upstream Ruby when a cask loads.

The rolling resolver is a custom-tap extension using Homebrew's internal Sparkle and curl APIs; it needs checking when those APIs change. Ordinary casks such as [Bartender](https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/b/bartender.rb) and [CodexBar](https://github.com/steipete/homebrew-tap/blob/main/Casks/codexbar.rb) instead publish versioned URLs and SHA-256 pins. [Sparkle's signing documentation](https://sparkle-project.org/documentation/publishing/#secure-your-update) describes the archive signatures used here. App self-updates remain under Sparkle's control.

Run `brew ruby test/sparkle_download_strategy.rb` for local signature, cache, channel and extraction checks. The test generates its own keys and archive, uses HTTP fixtures, and requires no downloads or additional gems.
