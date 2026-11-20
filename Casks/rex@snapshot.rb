cask "rex@snapshot" do
  version "0.1.0,2076"
  sha256 "3983f1b1e599bf39536576e6a5586089da4998bdfe711bd2fe57d668ba37d355"

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
