# typed: strict
# frozen_string_literal: true

require "download_strategy"
require "livecheck/strategy/xml"
require "livecheck/strategy/sparkle"
require "openssl"

# Resolve signed Sparkle archives; Homebrew handles downloading and extraction.
# Subclasses supply the app's trusted SUPublicEDKey, independently of the feed.
class SparkleDownloadStrategy < CurlDownloadStrategy
  CHANNELS = [].freeze
  REQUIRE_SIGNED_FEED = false
  SPARKLE_NAMESPACE = "http://www.andymatuschak.org/xml-namespaces/sparkle"

  sig { override.params(timeout: T.nilable(T.any(Float, Integer))).void }
  def fetch(timeout: nil)
    super
    begin
      data = cached_location.binread
      expected_size = Integer(enclosure["length"].to_s, 10)
      valid = data.bytesize == expected_size && public_key.verify(nil, archive_signature, data)
      raise CurlDownloadStrategyError.new(url, "Sparkle archive size or signature verification failed.") unless valid

      digest = Digest::SHA256.hexdigest(data)
      ohai "Verified Sparkle signature; SHA-256: #{digest}" unless quiet?
    rescue ArgumentError, OpenSSL::OpenSSLError, CurlDownloadStrategyError => e
      clear_cache
      raise CurlDownloadStrategyError.new(url, "Sparkle archive verification failed: #{e.message}")
    end
  end

  sig { override.returns(Pathname) }
  def cached_location
    identity = Digest::SHA256.hexdigest([url, release.nice_version, archive_signature].join("\n"))
    @cached_location ||= HOMEBREW_CACHE/"downloads/#{identity}--#{resolved_basename}"
  end

  private

  sig { returns(String) }
  def resolved_basename
    release_version = release.nice_version.tr(",", "-")
    extension = Pathname(parse_basename(release.url, search_query: false)).extname
    Utils.safe_filename("#{name}-#{release_version}#{extension}")
  end

  sig { returns(Homebrew::Livecheck::Strategy::Sparkle::Item) }
  def release
    return @release if @release

    sparkle = Homebrew::Livecheck::Strategy::Sparkle
    items = sparkle.filter_items(sparkle.items_from_content(feed)).select do |item|
      allowed_channel = item.channel.blank? || self.class::CHANNELS.include?(item.channel)
      item.bundle_version.present? && allowed_channel && (item.minimum_system_version.blank? ||
        Version.new(item.minimum_system_version) <= Version.new(MacOS.version.to_s))
    end
    item = sparkle.sort_items(items).first
    unless item&.version.present?
      raise CurlDownloadStrategyError.new(url, "No compatible release in the Sparkle feed.")
    end

    validate_url(item.url.to_s)
    @release = T.let(item, T.nilable(Homebrew::Livecheck::Strategy::Sparkle::Item))
  rescue REXML::ParseException, URI::InvalidURIError => e
    raise CurlDownloadStrategyError.new(url, "Invalid Sparkle feed: #{e.message}")
  end

  sig { returns(String) }
  def feed
    return @feed if @feed

    validate_url(url)
    remaining = Utils::Timer.remaining!(@fetch_end_time)
    xml = curl_output("--fail", "--silent", "--location", "--proto-redir", "=https", url,
                      timeout: [remaining || 60, 60].min).stdout.b
    footer = xml.match(/<!-- sparkle-signatures:\s*edSignature: (\S+)\s+length: (\d+)\s*-->\s*\z/)
    if footer
      length = Integer(footer[2], 10)
      valid = length == footer.begin(0) && public_key.verify(nil, footer[1].unpack1("m0"), xml.byteslice(0, length))
      raise CurlDownloadStrategyError.new(url, "Invalid Sparkle feed signature.") unless valid
    elsif self.class::REQUIRE_SIGNED_FEED
      raise CurlDownloadStrategyError.new(url, "Missing Sparkle feed signature.")
    end
    @feed = T.let(xml, T.nilable(String))
  rescue ArgumentError, OpenSSL::OpenSSLError => e
    raise CurlDownloadStrategyError.new(url, "Invalid Sparkle feed signature: #{e.message}")
  end

  sig { returns(REXML::Element) }
  def enclosure
    return @enclosure if @enclosure

    document = Homebrew::Livecheck::Strategy::Xml.parse_xml(feed)
    element = document.get_elements("rss/channel/item/enclosure").find { |node| node["url"] == release.url }
    raise CurlDownloadStrategyError.new(url, "Missing Sparkle archive enclosure.") unless element

    @enclosure = T.let(element, T.nilable(REXML::Element))
  end

  sig { returns(String) }
  def archive_signature
    attribute = enclosure.attributes.get_attribute_ns(SPARKLE_NAMESPACE, "edSignature")
    signature = attribute&.value.to_s.unpack1("m0")
    if signature.bytesize != 64
      raise CurlDownloadStrategyError.new(url, "Missing or invalid Sparkle archive signature.")
    end

    signature
  rescue ArgumentError => e
    raise CurlDownloadStrategyError.new(url, "Invalid Sparkle archive signature: #{e.message}")
  end

  sig { returns(OpenSSL::PKey::PKey) }
  def public_key
    return @public_key if @public_key

    unless self.class.const_defined?(:PUBLIC_KEY)
      raise CurlDownloadStrategyError.new(url, "Configure the app's trusted SUPublicEDKey in a strategy subclass.")
    end

    raw = self.class::PUBLIC_KEY.unpack1("m0")
    raise ArgumentError, "Ed25519 public keys must contain 32 bytes" if raw.bytesize != 32

    # RFC 8410 SubjectPublicKeyInfo header for a raw Ed25519 key.
    der = ["302a300506032b6570032100"].pack("H*") + raw
    @public_key = T.let(OpenSSL::PKey.read(der), T.nilable(OpenSSL::PKey::PKey))
  rescue ArgumentError, OpenSSL::OpenSSLError => e
    raise CurlDownloadStrategyError.new(url, "Invalid Sparkle public key: #{e.message}")
  end

  sig { params(value: String).void }
  def validate_url(value)
    uri = URI(value)
    valid = uri.scheme == "https" && uri.host.present? && uri.userinfo.nil?
    unless valid
      raise CurlDownloadStrategyError.new(url, "Sparkle downloads require an HTTPS URL without embedded credentials.")
    end
  rescue URI::InvalidURIError => e
    raise CurlDownloadStrategyError.new(url, "Invalid Sparkle URL: #{e.message}")
  end

  sig { params(url: String, timeout: T.nilable(T.any(Float, Integer))).returns(URLMetadata) }
  def resolve_url_basename_time_file_size(url, timeout: nil)
    return super if url != self.url

    # This path belongs to this exact build, so it needs no CDN request on reuse.
    return [url, resolved_basename, nil, nil, nil, false] if cached_location.exist?

    metadata = super(release.url, timeout:)
    metadata[5] = true
    metadata
  end
end
