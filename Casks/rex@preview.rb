cask "rex@preview" do
  version "0.1.0,2116"
  sha256 "6424b057df8519446966513100a5246539530220d3c6be647e78f8a032e9fced"

  url "https://blob.superlogical.com/public/rex-app/preview/Rex-#{version.csv.first}-#{version.csv.second}.dmg"
  name "Rex Preview"
  desc "Terminal and multiplexer (preview)"
  homepage "https://www.superlogical.com/rex"

  livecheck do
    url "https://blob.superlogical.com/public/rex-app/preview/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
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
