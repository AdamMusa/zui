# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "net/http"
require "openssl"
require "tmpdir"
require "timeout"
require "uri"
require "zlib"
require "rubygems/package"

module Zui
  class Client
    FORMAT = 1
    MAX_ARCHIVE_BYTES = 1_073_741_824
    MAX_EXPANDED_BYTES = 2_147_483_648
    MAX_ENTRIES = 100_000
    REDIRECT_LIMIT = 5

    attr_reader :platform, :version

    def initialize(platform: Platform.current, version: VERSION, environment: ENV,
                   cache_root: nil, release_base_url: nil, downloader: nil)
      @platform = platform.assert_supported!
      @version = version.to_s
      @environment = environment
      @cache_root = cache_root
      @release_base_url = release_base_url
      @downloader = downloader || method(:download)
    end

    def root
      override = @environment["ZUI_CLIENT_ROOT"]
      return File.expand_path(override) if override && !override.empty?

      File.join(cache_root, "zui", "clients", version, platform.id)
    end

    def configured?
      validate!(root)
      true
    rescue ArgumentError, Errno::ENOENT
      false
    end

    def configure!
      return root if configured?
      raise ArgumentError, "ZUI_CLIENT_ROOT is not a valid configured client: #{root}" if client_root_override?

      FileUtils.mkdir_p(File.dirname(root))
      File.open("#{root}.lock", File::RDWR | File::CREAT, 0o600) do |lock|
        lock.flock(File::LOCK_EX)
        return root if configured?

        install_download!
      end
      root
    end

    def executable
      manifest = validate!(root)
      File.join(root, manifest.fetch("executable"))
    end

    def executable_relative_path
      validate!(root).fetch("executable")
    end

    def environment_entries
      manifest = validate!(root)
      manifest.fetch("environment", {}).transform_values do |paths|
        Array(paths).map { |path| safe_manifest_path!(path, "client environment path") }
      end
    end

    def environment(base = ENV.to_h, client_root: root)
      environment_entries.each_with_object(base.to_h.dup) do |(name, paths), result|
        unless name.match?(/\A[A-Z][A-Z0-9_]*\z/)
          raise ArgumentError, "invalid environment variable in Zui client: #{name.inspect}"
        end

        resolved = paths.map { |path| File.join(client_root, path) }
        previous = result[name]
        resolved << previous unless previous.nil? || previous.empty?
        result[name] = resolved.join(File::PATH_SEPARATOR)
      end
    end

    def copy_to(destination)
      manifest = validate!(root)
      raise ArgumentError, "client destination already exists: #{destination}" if File.exist?(destination)

      created = true
      FileUtils.mkdir_p(destination)
      FileUtils.cp_r(Dir.children(root).map { |entry| File.join(root, entry) }, destination)
      validate!(destination)
      manifest
    rescue StandardError
      FileUtils.remove_entry(destination) if created && destination && File.exist?(destination)
      raise
    end

    def manifest
      validate!(root)
    end

    def archive_name = "zui-client-#{platform.id}.tar.gz"

    def archive_url
      override = @environment["ZUI_CLIENT_ARCHIVE"]
      return File.expand_path(override) if override && !override.empty?

      URI.join("#{release_base_url}/", archive_name)
    end

    def checksum_url
      override = @environment["ZUI_CLIENT_CHECKSUM"]
      return File.expand_path(override) if override && !override.empty?

      source = archive_url
      source.is_a?(URI) ? URI("#{source}.sha256") : "#{source}.sha256"
    end

    private

    def install_download!
      Dir.mktmpdir(".zui-client-", File.dirname(root)) do |temporary|
        archive = File.join(temporary, archive_name)
        checksum = "#{archive}.sha256"
        @downloader.call(archive_url, archive)
        @downloader.call(checksum_url, checksum)
        verify_checksum!(archive, checksum)

        staged = File.join(temporary, "client")
        FileUtils.mkdir_p(staged)
        extract!(archive, staged)
        validate!(staged)

        installed = "#{root}.install-#{Process.pid}-#{rand(1_000_000)}"
        File.rename(staged, installed)
        if File.exist?(root)
          invalid = "#{root}.invalid-#{Time.now.to_i}-#{Process.pid}"
          File.rename(root, invalid)
        end
        File.rename(installed, root)
      ensure
        FileUtils.remove_entry(installed) if installed && File.exist?(installed)
      end
      validate!(root)
      root
    end

    def validate!(directory)
      manifest_path = File.join(directory, "client.json")
      raise ArgumentError, "Zui client manifest not found: #{manifest_path}" unless File.file?(manifest_path)
      raise ArgumentError, "Zui client manifest is too large" if File.size(manifest_path) > 65_536

      manifest = JSON.parse(File.read(manifest_path))
      raise ArgumentError, "invalid Zui client manifest root" unless manifest.is_a?(Hash)
      expected = {
        "format" => FORMAT,
        "framework" => "zui",
        "client_version" => version,
        "platform" => platform.id
      }
      expected.each do |key, value|
        actual = manifest[key]
        raise ArgumentError, "invalid Zui client #{key}: expected #{value.inspect}, got #{actual.inspect}" unless actual == value
      end
      raise ArgumentError, "Zui client is not bundle capable" unless manifest["bundle_capable"] == true
      unless manifest["payload"] == %w[native-host qt-engine]
        raise ArgumentError, "invalid Zui client payload: expected native host and Qt engine only"
      end

      required_paths = manifest["required_paths"]
      unless required_paths.is_a?(Array) && !required_paths.empty? &&
             required_paths.all? { |path| path.is_a?(String) }
        raise ArgumentError, "invalid Zui client required paths"
      end
      required_paths.each do |path|
        relative_path = safe_manifest_path!(path, "client required path")
        resolved_path = File.join(directory, relative_path)
        raise ArgumentError, "Zui client required path is missing: #{resolved_path}" unless File.exist?(resolved_path)
      end

      relative = safe_manifest_path!(manifest["executable"], "client executable")
      executable = File.join(directory, relative)
      unless File.file?(executable) && executable_for_target?(executable)
        raise ArgumentError, "Zui client executable is missing or not executable: #{executable}"
      end

      client_environment = manifest.fetch("environment", {})
      raise ArgumentError, "invalid Zui client environment" unless client_environment.is_a?(Hash)
      client_environment.each do |name, paths|
        unless name.is_a?(String) && name.match?(/\A[A-Z][A-Z0-9_]*\z/)
          raise ArgumentError, "invalid client environment entry: #{name.inspect}"
        end
        unless paths.is_a?(Array) && !paths.empty? && paths.all? { |path| path.is_a?(String) }
          raise ArgumentError, "invalid client environment paths for #{name}"
        end
        paths.each do |path|
          relative_path = safe_manifest_path!(path, "client environment path")
          resolved_path = File.join(directory, relative_path)
          raise ArgumentError, "Zui client environment path is missing: #{resolved_path}" unless File.exist?(resolved_path)
        end
      end
      manifest
    rescue JSON::ParserError => error
      raise ArgumentError, "invalid Zui client manifest: #{error.message}"
    end

    def executable_for_target?(path)
      # Windows cannot represent the POSIX executable bit when validating a
      # Linux or macOS archive. Native POSIX clients still require that bit.
      platform.windows? || Gem.win_platform? || File.executable?(path)
    end

    def verify_checksum!(archive, checksum_file)
      expected = File.read(checksum_file, 4096)[/\A\s*([0-9a-fA-F]{64})(?:\s|\z)/, 1]
      raise ArgumentError, "invalid Zui client checksum file" unless expected

      actual = Digest::SHA256.file(archive).hexdigest
      raise ArgumentError, "Zui client checksum mismatch" unless actual.casecmp?(expected)
    end

    def extract!(archive, destination)
      count = 0
      expanded = 0
      Zlib::GzipReader.open(archive) do |gzip|
        Gem::Package::TarReader.new(gzip) do |tar|
          tar.each do |entry|
            count += 1
            raise ArgumentError, "Zui client archive contains too many files" if count > MAX_ENTRIES

            relative = safe_relative_path!(entry.full_name, "archive entry")
            target = File.join(destination, relative)
            if entry.directory?
              FileUtils.mkdir_p(target)
            elsif entry.file?
              expanded += entry.header.size
              raise ArgumentError, "Zui client archive expands beyond the safety limit" if expanded > MAX_EXPANDED_BYTES

              FileUtils.mkdir_p(File.dirname(target))
              File.open(target, "wb", entry.header.mode & 0o111 == 0 ? 0o644 : 0o755) do |file|
                IO.copy_stream(entry, file)
              end
            else
              raise ArgumentError, "Zui client archive contains an unsupported link or special file: #{entry.full_name}"
            end
          end
        end
      end
    rescue Zlib::GzipFile::Error, Gem::Package::TarInvalidError => error
      raise ArgumentError, "invalid Zui client archive: #{error.message}"
    end

    def download(source, destination, redirects = REDIRECT_LIMIT)
      if source.is_a?(String) && File.file?(source)
        FileUtils.cp(source, destination)
        return destination
      end
      uri = source.is_a?(URI) ? source : URI(source.to_s)
      if uri.scheme == "file"
        FileUtils.cp(URI::DEFAULT_PARSER.unescape(uri.path), destination)
        return destination
      end
      raise ArgumentError, "Zui client download must use HTTPS" unless uri.scheme == "https"
      raise ArgumentError, "too many Zui client download redirects" if redirects.negative?

      http = Net::HTTP.new(uri.host, uri.port, :ENV)
      http.use_ssl = true
      http.open_timeout = 20
      http.read_timeout = 120
      http.write_timeout = 120 if http.respond_to?(:write_timeout=)
      http.start do
        http.request(Net::HTTP::Get.new(uri.request_uri)) do |response|
          case response
          when Net::HTTPSuccess
            written = 0
            File.open(destination, "wb") do |file|
              response.read_body do |chunk|
                written += chunk.bytesize
                raise ArgumentError, "Zui client download exceeds the safety limit" if written > MAX_ARCHIVE_BYTES
                file.write(chunk)
              end
            end
          when Net::HTTPRedirection
            location = response["location"] || raise(ArgumentError, "Zui client redirect has no location")
            return download(URI.join(uri, location), destination, redirects - 1)
          else
            raise ArgumentError, "Zui client download failed: HTTP #{response.code}"
          end
        end
      end
      destination
    rescue URI::InvalidURIError => error
      raise ArgumentError, "invalid Zui client URL: #{error.message}"
    rescue Timeout::Error, SocketError, OpenSSL::SSL::SSLError => error
      raise ArgumentError, "Zui client download failed: #{error.class}: #{error.message}"
    end

    def safe_relative_path!(value, label)
      path = value.to_s
      if path.empty? || path.include?("\\") || path.match?(/[[:cntrl:]]/) || path.start_with?("/") ||
         path.match?(/\A[A-Za-z]:/) ||
         path.split("/").any? { |part| part.empty? || part == "." || part == ".." }
        raise ArgumentError, "unsafe #{label}: #{value.inspect}"
      end
      path
    end

    def safe_manifest_path!(value, label)
      path = safe_relative_path!(value, label)
      unless path.match?(/\A[A-Za-z0-9._+ -]+(?:\/[A-Za-z0-9._+ -]+)*\z/)
        raise ArgumentError, "unsafe #{label}: #{value.inspect}"
      end
      path
    end

    def release_base_url
      @release_base_url || @environment["ZUI_CLIENT_BASE_URL"] ||
        "https://github.com/AdamMusa/zui/releases/download/v#{version}"
    end

    def cache_root
      return File.expand_path(@cache_root) if @cache_root

      override = @environment["ZUI_CACHE_HOME"]
      return File.expand_path(override) if override && !override.empty?

      home = @environment["HOME"] || @environment["USERPROFILE"] || Dir.home
      if platform.windows?
        @environment["LOCALAPPDATA"] || @environment["APPDATA"] || File.join(home, "AppData", "Local")
      elsif platform.macos?
        File.join(home, "Library", "Caches")
      else
        @environment["XDG_CACHE_HOME"] || File.join(home, ".cache")
      end
    end

    def client_root_override?
      value = @environment["ZUI_CLIENT_ROOT"]
      value && !value.empty?
    end

  end
end
