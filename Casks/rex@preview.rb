require "#{HOMEBREW_LIBRARY}/Taps/rajaniraiyn/homebrew-tap/lib/rex_download_strategy"

cask "rex@preview" do
  version :latest
  sha256 :no_check

  url "https://blob.superlogical.com/public/rex-app/preview/appcast.xml",
      using: RexDownloadStrategy
  name "Rex Preview"
  desc "Terminal and multiplexer (preview)"
  homepage "https://www.superlogical.com/rex"

  conflicts_with cask: "rajaniraiyn/tap/rex@snapshot"
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
