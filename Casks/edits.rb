require "#{HOMEBREW_LIBRARY}/Taps/rajaniraiyn/homebrew-tap/lib/edits_download_strategy"

cask "edits" do
  version :latest
  sha256 :no_check

  url "https://edits.instagram.com/macos/appcast.xml",
      using: EditsDownloadStrategy
  name "Edits"
  desc "Video editor from Instagram"
  homepage "https://edits.instagram.com/desktop/"

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Edits.app"

  uninstall quit: "com.burbn.basel.mac"

  zap trash: [
    "~/Library/Application Scripts/com.burbn.basel.mac",
    "~/Library/Application Scripts/group.com.burbn.basel.mac",
    "~/Library/Caches/com.burbn.basel.mac",
    "~/Library/Containers/com.burbn.basel.mac",
    "~/Library/Group Containers/group.com.burbn.basel.mac",
    "~/Library/HTTPStorages/com.burbn.basel.mac",
    "~/Library/Preferences/com.burbn.basel.mac.plist",
    "~/Library/Saved Application State/com.burbn.basel.mac.savedState",
  ]

  caveats <<~EOS
    Edits requires macOS 15.1 or later.
  EOS
end
