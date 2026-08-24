# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "client_packager"

module Zui
  # Internal CI/release builder. It is deliberately not used by `zui configure`.
  class ClientBuilder
    BROWSER_PAYLOAD_PATTERN = %r{
      (?:\A|/)(?:
        QtWebEngine[^/]* |
        QtWebChannel[^/]* |
        QtPositioning |
        qtwebengine[^/]* |
        (?:lib)?qwebengine[^/]* |
        webchannel[^/]* |
        (?:lib)?Qt6(?:WebEngine|WebChannel|Positioning)[^/]* |
        position
      )(?:/|\z)
    }ix

    def initialize(platform: Platform.current, framework_root: FRAMEWORK_ROOT, environment: ENV)
      @platform = platform.assert_supported!
      @framework_root = framework_root
      @environment = environment
    end

    def build!(output:)
      Dir.mktmpdir("zui-client-build-") do |temporary|
        build = File.join(temporary, "build")
        stage = File.join(temporary, "stage")
        cmake = command!("cmake")
        run!([cmake, "-S", File.join(@framework_root, "native"), "-B", build,
              "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_PREFIX=#{stage}"], timeout: 240)
        run!([cmake, "--build", build, "--config", "Release", "--parallel"], timeout: 900)
        run!([cmake, "--install", build, "--config", "Release"], timeout: 900)

        qt = qt_installation
        install_catalog_runtime(stage, qt)
        ClientPackager.new(platform: @platform).package(
          source: stage,
          output:,
          executable: executable_relative_path,
          qt_version: qt.fetch("QT_VERSION")
        )
      end
    end

    private

    def run!(arguments, timeout:)
      result = Command.run(arguments, timeout:, max_output_bytes: 32_000_000)
      return if result.success?

      raise ArgumentError, "client build command failed (#{arguments.first}):\n#{result.stdout}\n#{result.stderr}"
    end

    def install_catalog_runtime(stage, qt)
      unless @platform.macos? # macdeployqt patches and embeds the scanned QML modules in the app.
        copy_tree(qt.fetch("QT_INSTALL_QML"), File.join(stage, "qml"))
        copy_tree(qt.fetch("QT_INSTALL_PLUGINS"), File.join(stage, "plugins"))
        copy_tree(qt["QT_INSTALL_TRANSLATIONS"], File.join(stage, "translations"))

        if @platform.linux?
          install_linux_libraries(stage, qt)
          File.write(File.join(stage, "bin", "qt.conf"), <<~CONF)
            [Paths]
            Prefix=..
            Libraries=lib
            Plugins=plugins
            Qml2Imports=qml
            LibraryExecutables=libexec
            Data=.
            Translations=translations
          CONF
        else
          install_windows_libraries(stage, qt)
        end
      end

      purge_browser_payload!(stage)
    end

    def install_linux_libraries(stage, qt)
      destination = File.join(stage, "lib")
      FileUtils.mkdir_p(destination)
      Dir[File.join(qt.fetch("QT_INSTALL_LIBS"), "libQt6*.so.6")].sort.each do |library|
        FileUtils.cp(library, File.join(destination, File.basename(library)))
      end
    end

    def install_windows_libraries(stage, qt)
      destination = File.join(stage, "bin")
      FileUtils.mkdir_p(destination)
      Dir[File.join(qt.fetch("QT_INSTALL_BINS"), "Qt6*.dll")].sort.each do |library|
        FileUtils.cp(library, File.join(destination, File.basename(library)))
      end
    end

    def copy_tree(source, destination)
      return unless source && File.directory?(source)

      FileUtils.mkdir_p(destination)
      entries = Dir.children(source)
      FileUtils.cp_r(entries.map { |entry| File.join(source, entry) }, destination) unless entries.empty?
    end

    def purge_browser_payload!(stage)
      browser_payloads(stage).sort_by { |path| -path.count(File::SEPARATOR) }.each do |path|
        FileUtils.remove_entry(path) if File.exist?(path) || File.symlink?(path)
      end

      remaining = browser_payloads(stage)
      return if remaining.empty?

      raise ArgumentError, "desktop client contains forbidden WebEngine payload: #{remaining.first}"
    end

    def browser_payloads(stage)
      Dir.glob(File.join(stage, "**", "*"), File::FNM_DOTMATCH).select do |path|
        next false if [".", ".."].include?(File.basename(path))

        relative = path.delete_prefix("#{stage}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
        relative.match?(BROWSER_PAYLOAD_PATTERN)
      end
    end

    def qt_installation
      qmake = command!("qmake6", "qmake")
      keys = %w[
        QT_VERSION QT_INSTALL_BINS QT_INSTALL_LIBS
        QT_INSTALL_PLUGINS QT_INSTALL_QML QT_INSTALL_TRANSLATIONS
      ]
      keys.to_h do |key|
        result = Command.run([qmake, "-query", key], timeout: 30, max_output_bytes: 64_000)
        raise ArgumentError, "could not query #{key} from Qt" unless result.success?
        [key, result.stdout.strip]
      end
    end

    def command!(*names)
      @environment.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
        names.each do |name|
          command_names(name).each do |candidate|
            path = File.join(directory, candidate)
            return path if File.executable?(path) && !File.directory?(path)
          end
        end
      end
      raise ArgumentError, "release client builder requires #{names.join(' or ')}"
    end

    def command_names(name)
      return [name] unless @platform.windows? && File.extname(name).empty?

      extensions = @environment.fetch("PATHEXT", ".COM;.EXE;.BAT;.CMD").split(";")
      [name] + extensions.flat_map { |extension| ["#{name}#{extension.downcase}", "#{name}#{extension.upcase}"] }.uniq
    end

    def executable_relative_path
      if @platform.macos?
        "zui-host.app/Contents/MacOS/zui-host"
      elsif @platform.windows?
        "bin/zui-host.exe"
      else
        "bin/zui-host"
      end
    end
  end
end
