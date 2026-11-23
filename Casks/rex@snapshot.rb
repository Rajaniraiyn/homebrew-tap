cask "rex@snapshot" do
  version "0.1.0,2099"
  sha256 "c26ea58990029e551ea4abf024cdef9879a5eda053814ef24f5e7f20f83ea423"

  url "https://blob.superlogical.com/public/rex-app/snapshot/Rex-#{version.csv.first}-#{version.csv.second}.dmg"
  name "Rex Snapshot"
  desc "Terminal and multiplexer (snapshot)"
  homepage "https://www.superlogical.com/rex"

  livecheck do
    url "https://blob.superlogical.com/public/rex-app/snapshot/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
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
