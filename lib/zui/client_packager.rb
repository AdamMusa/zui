# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"

module Zui
  # Internal release tooling used by native CI jobs.
  class ClientPackager
    attr_reader :platform

    def initialize(platform: Platform.current, version: VERSION, source_date_epoch: nil,
                   framework_root: FRAMEWORK_ROOT)
      @platform = platform.assert_supported!
      @version = version.to_s
      @source_date_epoch = ReproducibleBuild.epoch(source_date_epoch)
      @framework_root = File.expand_path(framework_root)
    end

    def package(source:, output:, executable:, qt_version: nil)
      source = File.expand_path(source)
      output = File.expand_path(output)
      raise ArgumentError, "client staging directory not found: #{source}" unless File.directory?(source)

      executable = safe_relative_path!(executable)
      executable_path = File.join(source, executable)
      unless File.file?(executable_path) && executable_for_target?(executable_path)
        raise ArgumentError, "client executable is missing or not executable: #{executable_path}"
      end
      reject_framework_payload!(source)
      validate_runtime_paths!(source)
      validate_archive_paths!(source)

      write_manifest(source, executable, qt_version)
      FileUtils.mkdir_p(output)
      archive = File.join(output, "zui-client-#{platform.id}.tar.gz")
      raise ArgumentError, "client archive already exists: #{archive}" if File.exist?(archive)

      ReproducibleBuild.tar_gzip(
        archive, root: source, entries: Dir.children(source), epoch: @source_date_epoch,
        include_symlinks: false
      )
      checksum = Digest::SHA256.file(archive).hexdigest
      File.write("#{archive}.sha256", "#{checksum}  #{File.basename(archive)}\n")
      archive
    end

    private

    def executable_for_target?(path)
      # Windows filesystems do not preserve POSIX executable permission bits, so
      # cross-platform layout tests and release tooling cannot inspect that bit
      # for a Linux or macOS payload. Native POSIX builds still enforce it.
      platform.windows? || Gem.win_platform? || File.executable?(path)
    end

    def write_manifest(source, executable, qt_version)
      File.write(File.join(source, "client.json"), JSON.pretty_generate(
        "format" => Client::FORMAT,
        "framework" => "zui",
        "client_version" => @version,
        "platform" => platform.id,
        "runtime_contract_sha256" => Client.runtime_contract(framework_root: @framework_root),
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
        {
          "QT_PLUGIN_PATH" => ["zui-host.app/Contents/PlugIns"],
          "QML_IMPORT_PATH" => ["zui-host.app/Contents/Resources/qml"],
          "QML2_IMPORT_PATH" => ["zui-host.app/Contents/Resources/qml"]
        }
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

    def validate_archive_paths!(source)
      Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH).sort.each do |path|
        next if %w[. ..].include?(File.basename(path))

        safe_relative_path!(path.delete_prefix("#{source}#{File::SEPARATOR}").tr(File::SEPARATOR, "/"))
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
