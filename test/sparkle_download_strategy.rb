# typed: strict
# frozen_string_literal: true

# Run with: brew ruby test/sparkle_download_strategy.rb
require "tmpdir"
require_relative "../lib/sparkle_download_strategy"

signer = OpenSSL::PKey.generate_key("ED25519")
strategy_class = Class.new(SparkleDownloadStrategy)
strategy_class.const_set(:PUBLIC_KEY, [signer.public_to_der.byteslice(-32, 32)].pack("m0"))
response_class = Struct.new(:stdout)
checks = 0
assert = lambda do |condition, message|
  raise message unless condition

  checks += 1
end
reject = lambda do |&operation|
  operation.call
rescue CurlDownloadStrategyError
  checks += 1
else
  raise "Expected Sparkle verification to reject the input"
end

Dir.mktmpdir("sparkle-test-") do |directory|
  root = Pathname(directory)
  (root/"Example.app").mkpath
  (root/"Example.app/message.txt").write("signed archive fixture")
  success = system("/usr/bin/ditto", "-c", "-k", "--keepParent", root/"Example.app", root/"fixture.zip")
  raise "Could not create test archive" unless success

  payload = (root/"fixture.zip").binread
  archive_signature = [signer.sign(nil, payload)].pack("m0")
  xml = <<~XML
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel>
      <item><sparkle:version>2026.1</sparkle:version><sparkle:shortVersionString>2.0b1</sparkle:shortVersionString>
      <enclosure url="https://arbitrary-cdn.example/archive.zip?tracking=example.net" length="#{payload.bytesize}"
        sparkle:edSignature="#{archive_signature}"/></item>
    </channel></rss>
  XML
  sign_feed = lambda do |content|
    signature = [signer.sign(nil, content)].pack("m0")
    content + "<!-- sparkle-signatures:\nedSignature: #{signature}\nlength: #{content.bytesize}\n-->\n"
  end

  sequence = 0
  make = lambda do |content, body: payload, klass: strategy_class|
    sequence += 1
    cache = root/sequence.to_s
    cache.mkpath
    strategy = klass.new("https://arbitrary-feed.example/appcast.xml", "fixture", "latest", cache:)
    strategy.quiet!
    strategy.define_singleton_method(:curl_output) do |*_, **_|
      @feed_requests = (@feed_requests || 0) + 1
      response_class.new(content)
    end
    strategy.define_singleton_method(:curl_headers) do |*_, **_|
      { responses: [{ headers: { "content-length" => body.bytesize.to_s } }] }
    end
    strategy.define_singleton_method(:_curl_download) do |_, destination, _|
      @archive_requests = (@archive_requests || 0) + 1
      destination.dirname.mkpath
      destination.binwrite(body)
    end
    # Keep Homebrew's real cache/lock/download logic inside this test's directory.
    strategy.define_singleton_method(:cached_location) do
      super().sub(HOMEBREW_CACHE.to_s, cache.to_s)
    end
    strategy
  end

  strategy = make.call(xml)
  strategy.fetch
  assert.call(strategy.cached_location.extname == ".zip", "CDN query changed the archive format")
  assert.call(strategy.cached_location.binread == payload, "Valid signed archive was not downloaded")
  strategy.fetch
  assert.call(strategy.instance_variable_get(:@feed_requests) == 1, "Feed was fetched twice")
  assert.call(strategy.instance_variable_get(:@archive_requests) == 1, "Cached archive was downloaded twice")
  tracking = make.call(xml.sub("tracking=example.net", "tracking=other.example"))
  assert.call(strategy.cached_location.basename == tracking.cached_location.basename,
              "CDN tracking changed cache identity")
  retagged_signature = [signer.sign(nil, "different bytes")].pack("m0")
  retagged = make.call(xml.sub(archive_signature, retagged_signature))
  assert.call(strategy.cached_location.basename != retagged.cached_location.basename,
              "Re-signed builds share a cache")
  extraction = root/"extracted"
  extraction.mkpath
  Dir.chdir(extraction) { strategy.stage }
  assert.call((extraction/"Example.app/message.txt").read == "signed archive fixture", "Native ZIP extraction failed")

  # Reusing a cache must authenticate the bytes again, including same-size changes.
  strategy.cached_location.binwrite("x" * payload.bytesize)
  reject.call { strategy.fetch }
  assert.call(!strategy.cached_location.exist?, "Rejected cached archive was retained")
  corrupted = make.call(xml, body: "x" * payload.bytesize)
  reject.call { corrupted.fetch }
  assert.call(!corrupted.cached_location.exist?, "Rejected download was retained")
  reject.call { make.call(xml.sub("length=\"#{payload.bytesize}\"", 'length="1"')).fetch }
  reject.call { make.call(xml.sub(/sparkle:edSignature="[^"]+"/, "")).fetch }
  reject.call { make.call(xml.sub("#{archive_signature}\"", "invalid\"")).fetch }

  wrong_key = Class.new(strategy_class)
  other_key = OpenSSL::PKey.generate_key("ED25519")
  wrong_key.const_set(:PUBLIC_KEY, [other_key.public_to_der.byteslice(-32, 32)].pack("m0"))
  reject.call { make.call(xml, klass: wrong_key).fetch }
  reject.call { make.call(xml, klass: SparkleDownloadStrategy).fetch }
  strict_class = Class.new(strategy_class)
  strict_class.const_set(:REQUIRE_SIGNED_FEED, true)
  signed = sign_feed.call(xml)
  make.call(signed, klass: strict_class).fetch
  reject.call { make.call(xml, klass: strict_class).fetch }
  reject.call { make.call(signed.sub("2.0b1", "3.0b1"), klass: strict_class).fetch }
  reject.call do
    make.call(signed.sub("<!-- sparkle-signatures:", "<!--extra--><!-- sparkle-signatures:"),
              klass: strict_class).fetch
  end
  reject.call { make.call(signed, klass: wrong_key).fetch }

  reject.call { make.call(xml.sub("https://arbitrary-cdn.example", "http://arbitrary-cdn.example")).fetch }
  reject.call { make.call(xml.sub("https://arbitrary-cdn.example", "https://secret@arbitrary-cdn.example")).fetch }
  reject.call { make.call("<broken XML").fetch }
  missing_version = xml.gsub(%r{<sparkle:(?:shortVersionString|version)>[^<]+</sparkle:[^>]+>}, "")
  reject.call { make.call(missing_version).fetch }
  reject.call { make.call(xml.sub("<item>", "<item><sparkle:channel>beta</sparkle:channel>")).fetch }
  beta_class = Class.new(strategy_class)
  beta_class.const_set(:CHANNELS, ["beta"].freeze)
  make.call(xml.sub("<item>", "<item><sparkle:channel>beta</sparkle:channel>"), klass: beta_class).fetch
  reject.call do
    make.call(xml.sub("<item>", "<item><sparkle:minimumSystemVersion>999.0</sparkle:minimumSystemVersion>")).fetch
  end
end
puts "#{checks} Sparkle checks passed (local HTTP fixtures, real OpenSSL signatures and Homebrew ZIP extraction)"
