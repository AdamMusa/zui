# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "rubygems/package"
require "zlib"

module Zui
  # Internal release tooling used by native CI jobs.
  class ClientPackager
    attr_reader :platform

    def initialize(platform: Platform.current, version: VERSION)
      @platform = platform.assert_supported!
      @version = version.to_s
    end

    def package(source:, output:, executable:, qt_version: nil)
      source = File.expand_path(source)
      output = File.expand_path(output)
      raise ArgumentError, "client staging directory not found: #{source}" unless File.directory?(source)

      executable = safe_relative_path!(executable)
      executable_path = File.join(source, executable)
      unless File.file?(executable_path) && (platform.windows? || File.executable?(executable_path))
        raise ArgumentError, "client executable is missing or not executable: #{executable_path}"
      end
      reject_framework_payload!(source)
      validate_runtime_paths!(source)

      write_manifest(source, executable, qt_version)
      FileUtils.mkdir_p(output)
      archive = File.join(output, "zui-client-#{platform.id}.tar.gz")
      raise ArgumentError, "client archive already exists: #{archive}" if File.exist?(archive)

      tar_path = "#{archive}.tar-#{Process.pid}"
      File.open(tar_path, "wb") do |tar_file|
        Gem::Package::TarWriter.new(tar_file) { |tar| add_tree(tar, source, source) }
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

    def write_manifest(source, executable, qt_version)
      File.write(File.join(source, "client.json"), JSON.pretty_generate(
        "format" => Client::FORMAT,
        "framework" => "zui",
        "client_version" => @version,
        "platform" => platform.id,
        "bundle_capable" => true,
        "executable" => executable,
        "environment" => runtime_environment,
        "required_paths" => required_runtime_paths,
        "qt_version" => qt_version,
        "payload" => %w[native-host qt-engine]
      ).concat("\n"))
    end

    def runtime_environment
      if platform.linux?
        {
          "LD_LIBRARY_PATH" => ["lib"],
          "QT_PLUGIN_PATH" => ["plugins"],
          "QML_IMPORT_PATH" => ["qml"],
          "QML2_IMPORT_PATH" => ["qml"]
        }
      elsif platform.windows?
        {
          "PATH" => ["bin"],
          "QT_PLUGIN_PATH" => ["plugins"],
          "QML_IMPORT_PATH" => ["qml"],
          "QML2_IMPORT_PATH" => ["qml"]
        }
      else
        {}
      end
    end

    def reject_framework_payload!(source)
      forbidden = [File.join(source, "app"), File.join(source, "lib", "zui.rb")]
      found = forbidden.find { |path| File.exist?(path) }
      raise ArgumentError, "native client contains application/framework payload: #{found}" if found
    end

    def validate_runtime_paths!(source)
      required_runtime_paths.each do |relative|
        path = File.join(source, relative)
        raise ArgumentError, "client runtime path is missing: #{path}" unless File.exist?(path)
      end
    end

    def required_runtime_paths
      if platform.linux?
        ["bin/zui-host", "lib/libQt6Core.so.6", "plugins", "qml"]
      elsif platform.windows?
        ["bin/zui-host.exe", "bin/Qt6Core.dll", "plugins", "qml"]
      else
        [
          "zui-host.app/Contents/MacOS/zui-host",
          "zui-host.app/Contents/Frameworks",
          "zui-host.app/Contents/PlugIns",
          "zui-host.app/Contents/Resources/qml"
        ]
      end
    end

    def add_tree(tar, root, current)
      Dir.children(current).sort.each do |name|
        path = File.join(current, name)
        relative = safe_relative_path!(path.delete_prefix("#{root}/"))
        stat = File.stat(path)
        if stat.directory?
          tar.mkdir(relative, stat.mode & 0o777)
          add_tree(tar, root, path)
        elsif stat.file?
          mode = stat.mode & 0o777
          tar.add_file(relative, mode) { |io| File.open(path, "rb") { |file| IO.copy_stream(file, io) } }
        else
          raise ArgumentError, "unsupported file in client staging directory: #{path}"
        end
      end
    end

    def safe_relative_path!(value)
      path = value.to_s
      if path.empty? || path.include?("\\") || path.match?(/[[:cntrl:]]/) || path.start_with?("/") ||
         path.match?(/\A[A-Za-z]:/) || path.split("/").any? { |part| part.empty? || part == "." || part == ".." }
        raise ArgumentError, "unsafe client path: #{value.inspect}"
      end
      path
    end
  end
end
