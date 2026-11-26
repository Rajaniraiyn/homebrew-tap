require "#{HOMEBREW_LIBRARY}/Taps/rajaniraiyn/homebrew-tap/lib/rex_download_strategy"

cask "rex@snapshot" do
  version :latest
  sha256 :no_check

  url "https://blob.superlogical.com/public/rex-app/snapshot/appcast.xml",
      using: RexDownloadStrategy
  name "Rex Snapshot"
  desc "Terminal and multiplexer (snapshot)"
  homepage "https://www.superlogical.com/rex"

  conflicts_with cask: "rajaniraiyn/tap/rex@preview"
  depends_on macos: :sequoia

  app "Rex.app"

  uninstall quit: "com.superlogical.rex"

  zap launchctl: "com.superlogical.rex.server.*",
      quit:      "com.superlogical.rex",
      trash:     [
        "~/.config/rex",
        "~/Library/Application Support/com.superlogical.rex",
        "~/Library/Application Support/rex",
        "~/Library/Caches/com.superlogical.rex",
        "~/Library/Containers/com.superlogical.rex",
        "~/Library/HTTPStorages/com.superlogical.rex",
        "~/Library/Logs/com.superlogical.rex",
        "~/Library/Preferences/com.superlogical.rex.plist",
        "~/Library/Saved Application State/com.superlogical.rex.savedState",
      ]
end
