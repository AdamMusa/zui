# frozen_string_literal: true

require "fileutils"
require "json"

module Zui
  class LiteRuntime < Client
    FORMAT = 1
    MRUBY_VERSION = "4.0.0"
    MRUBY_REVISION = "831da26b9021de0369d17b71b5667e2941a1a32d"
    MRUBY_JSON_REVISION = "f99d9428025469f2400f93c53b185f65f963e507"

    def root
      override = @environment["ZUI_LITE_RUNTIME_ROOT"]
      return File.expand_path(override) if override && !override.empty?

      File.join(cache_root, "zui", "runtimes", version, platform.id, "lite")
    end

    def archive_name = "zui-runtime-lite-#{platform.id}.tar.gz"

    def configure!
      return root if configured?
      if client_root_override?
        raise ArgumentError, "ZUI_LITE_RUNTIME_ROOT is not a valid configured lite runtime: #{root}"
      end

      super
    end

    def archive_url
      override = @environment["ZUI_LITE_RUNTIME_ARCHIVE"]
      return File.expand_path(override) if override && !override.empty?

      URI.join("#{release_base_url}/", archive_name)
    end

    def checksum_url
      override = @environment["ZUI_LITE_RUNTIME_CHECKSUM"]
      return File.expand_path(override) if override && !override.empty?

      source = archive_url
      source.is_a?(URI) ? URI("#{source}.sha256") : "#{source}.sha256"
    end

    def install(project:, destination:)
      unless configured?
        raise ArgumentError,
              "Zui lite runtime is not configured for #{platform.id}; run `zui doctor --fix` before bundling"
      end

      copy_to(destination)
      File.write(File.join(destination, "app.rb"), LiteSource.new(project:).call)
      ApplicationRuntime.new(
        engine: "mruby", version: manifest.fetch("engine_version"),
        executable: manifest.fetch("executable"), program: "app.rb", load_path: ""
      ).write(destination)
    end

    private

    def validate!(directory)
      manifest_path = File.join(directory, "lite-runtime.json")
      raise ArgumentError, "Zui lite runtime manifest not found: #{manifest_path}" unless File.file?(manifest_path)
      raise ArgumentError, "Zui lite runtime manifest is too large" if File.size(manifest_path) > 65_536

      manifest = JSON.parse(File.read(manifest_path))
      raise ArgumentError, "invalid Zui lite runtime manifest root" unless manifest.is_a?(Hash)
      expected = {
        "format" => FORMAT,
        "framework" => "zui",
        "zui_version" => version,
        "platform" => platform.id,
        "engine" => "mruby",
        "engine_version" => MRUBY_VERSION,
        "engine_revision" => MRUBY_REVISION,
        "json_revision" => MRUBY_JSON_REVISION,
        "payload" => ["mruby"]
      }
      expected.each do |key, value|
        actual = manifest[key]
        unless actual == value
          raise ArgumentError,
                "invalid Zui lite runtime #{key}: expected #{value.inspect}, got #{actual.inspect}"
        end
      end

      required_paths = manifest["required_paths"]
      unless required_paths.is_a?(Array) && !required_paths.empty? &&
             required_paths.all? { |path| path.is_a?(String) }
        raise ArgumentError, "invalid Zui lite runtime required paths"
      end
      required_paths.each do |path|
        relative = safe_manifest_path!(path, "lite runtime required path")
        resolved = File.join(directory, relative)
        raise ArgumentError, "Zui lite runtime required path is missing: #{resolved}" unless File.exist?(resolved)
      end

      relative = safe_manifest_path!(manifest["executable"], "lite runtime executable")
      executable = File.join(directory, relative)
      unless File.file?(executable) && executable_for_target?(executable)
        raise ArgumentError, "Zui lite runtime executable is missing or not executable: #{executable}"
      end
      manifest
    rescue JSON::ParserError => error
      raise ArgumentError, "invalid Zui lite runtime manifest: #{error.message}"
    end

    def release_base_url
      @release_base_url || @environment["ZUI_LITE_RUNTIME_BASE_URL"] ||
        "https://github.com/AdamMusa/zui/releases/download/v#{version}"
    end

    def client_root_override?
      value = @environment["ZUI_LITE_RUNTIME_ROOT"]
      value && !value.empty?
    end
  end
end
