# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "rubygems/package"
require "zlib"

module Zui
  # Internal release tooling used by native CI jobs.
  class LiteRuntimePackager
    attr_reader :platform

    def initialize(platform: Platform.current, version: VERSION)
      @platform = platform.assert_supported!
      @version = version.to_s
    end

    def package(executable:, output:)
      executable = File.expand_path(executable)
      output = File.expand_path(output)
      unless File.file?(executable) && executable_for_target?(executable)
        raise ArgumentError, "mruby executable is missing or not executable: #{executable}"
      end

      FileUtils.mkdir_p(output)
      archive = File.join(output, "zui-runtime-lite-#{platform.id}.tar.gz")
      raise ArgumentError, "lite runtime archive already exists: #{archive}" if File.exist?(archive)

      tar_path = "#{archive}.tar-#{Process.pid}"
      executable_name = platform.windows? ? "mruby.exe" : "mruby"
      executable_path = "bin/#{executable_name}"
      manifest = JSON.pretty_generate(
        "format" => LiteRuntime::FORMAT,
        "framework" => "zui",
        "zui_version" => @version,
        "platform" => platform.id,
        "engine" => "mruby",
        "engine_version" => LiteRuntime::MRUBY_VERSION,
        "engine_revision" => LiteRuntime::MRUBY_REVISION,
        "json_revision" => LiteRuntime::MRUBY_JSON_REVISION,
        "executable" => executable_path,
        "required_paths" => [executable_path],
        "payload" => ["mruby"]
      ).concat("\n")

      File.open(tar_path, "wb") do |tar_file|
        Gem::Package::TarWriter.new(tar_file) do |tar|
          tar.mkdir("bin", 0o755)
          mode = platform.windows? ? 0o644 : 0o755
          tar.add_file(executable_path, mode) do |io|
            File.open(executable, "rb") { |file| IO.copy_stream(file, io) }
          end
          tar.add_file("lite-runtime.json", 0o644) { |io| io.write(manifest) }
        end
      end
      Zlib::GzipWriter.open(archive) do |gzip|
        File.open(tar_path, "rb") { |tar_file| IO.copy_stream(tar_file, gzip) }
      end
      checksum = Digest::SHA256.file(archive).hexdigest
      File.write("#{archive}.sha256", "#{checksum}  #{File.basename(archive)}\n")
      archive
    ensure
      FileUtils.rm_f(tar_path) if tar_path
    end

    private

    def executable_for_target?(path)
      platform.windows? || Gem.win_platform? || File.executable?(path)
    end
  end
end
