# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "client_packager"

module Zui
  # Internal CI/release builder. It is deliberately not used by `zui configure`.
  class ClientBuilder
    LINUX_QML_ROOTS = %w[QML Qt QtCore QtMultimedia QtQml QtQuick QtQuick3D].freeze
    LINUX_QML_EXCLUSIONS = %w[
      Qt/labs/StyleKit Qt/labs/animation Qt/labs/settings Qt/labs/sharedimage Qt/labs/synchronizer
      Qt/labs/wavefrontmesh Qt/test QtQuick/Controls/FluentWinUI3 QtQuick/Controls/Imagine
      QtQuick/Controls/Material QtQuick/Controls/Universal QtQuick/Controls/designer QtQuick/LocalStorage
      QtQuick/Pdf QtQuick/Timeline QtQuick/tooling QtQuick3D/Effects QtQuick3D/Helpers
      QtQuick3D/MaterialEditor QtQuick3D/ParticleEffects QtQuick3D/Particles3D QtQuick3D/SpatialAudio
      QtQuick3D/Xr QtQuick3D/designer QtQuick3D/lightmapviewer QtQml/XmlListModel
    ].freeze
    LINUX_PLUGIN_DIRECTORIES = %w[
      assetimporters generic iconengines imageformats multimedia networkinformation platforminputcontexts
      platforms platformthemes tls wayland-decoration-client wayland-graphics-integration-client
      xcbglintegrations
    ].freeze
    LINUX_TRANSLATION_GLOBS = %w[
      qtbase_*.qm qtdeclarative_*.qm qtmultimedia_*.qm qtquickcontrols2_*.qm
    ].freeze
    LINUX_PRIVATE_LIBRARY_PREFIXES = %w[libQt6 libicu].freeze
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
        qml_scan_root = File.join(temporary, "qml-scan")
        Runtime.install_qml(qml_scan_root, framework_root: @framework_root)
        cmake = command!("cmake")
        run!([cmake, "-S", File.join(@framework_root, "native"), "-B", build,
              "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_PREFIX=#{stage}",
              "-DZUI_QML_SCAN_ROOT=#{qml_scan_root}"], timeout: 240)
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
      if @platform.linux?
        install_linux_qml(stage, qt)
        install_linux_plugins(stage, qt)
        install_linux_translations(stage, qt)
        install_linux_libraries(stage)
        File.write(File.join(stage, "bin", "qt.conf"), <<~CONF)
          [Paths]
          Prefix=..
          Libraries=lib
          Plugins=plugins
          Qml2Imports=qml
          Translations=translations
        CONF
      elsif @platform.macos?
        install_macos_qml_plugins(stage)
      end
      purge_browser_payload!(stage)
    end

    def install_macos_qml_plugins(stage)
      contents = File.join(stage, "zui-host.app", "Contents")
      qml_root = File.join(contents, "Resources", "qml")
      plugin_root = File.join(contents, "PlugIns", "quick")
      raise ArgumentError, "deployed macOS QML tree is missing: #{qml_root}" unless File.directory?(qml_root)
      raise ArgumentError, "deployed macOS QML plugins are missing: #{plugin_root}" unless File.directory?(plugin_root)

      Dir[File.join(qml_root, "**", "qmldir")].sort.each do |qmldir|
        plugin_names = File.foreach(qmldir).filter_map do |line|
          line[/\A\s*(?:optional\s+)?plugin\s+([A-Za-z0-9._+-]+)/, 1]
        end
        plugin_names.uniq.each do |plugin_name|
          destination = File.join(File.dirname(qmldir), "lib#{plugin_name}.dylib")
          next if File.file?(destination) && !File.symlink?(destination)

          source = [
            File.join(plugin_root, "lib#{plugin_name}.dylib"),
            File.join(plugin_root, "#{plugin_name}.dylib")
          ].find { |candidate| File.file?(candidate) }
          raise ArgumentError, "deployed macOS QML plugin is missing: #{plugin_name}" unless source

          FileUtils.rm_f(destination) if File.symlink?(destination)
          FileUtils.cp(source, destination)
        end
      end
    end

    def install_linux_qml(stage, qt)
      source = qt.fetch("QT_INSTALL_QML")
      destination = File.join(stage, "qml")
      FileUtils.mkdir_p(destination)
      LINUX_QML_ROOTS.each do |name|
        path = File.join(source, name)
        raise ArgumentError, "required Qt QML module is missing: #{path}" unless File.directory?(path)

        FileUtils.cp_r(path, destination)
      end
      LINUX_QML_EXCLUSIONS.each do |relative|
        path = File.join(destination, relative)
        FileUtils.remove_entry(path) if File.exist?(path) || File.symlink?(path)
      end
    end

    def install_linux_plugins(stage, qt)
      source = qt.fetch("QT_INSTALL_PLUGINS")
      destination = File.join(stage, "plugins")
      FileUtils.mkdir_p(destination)
      LINUX_PLUGIN_DIRECTORIES.each do |name|
        path = File.join(source, name)
        FileUtils.cp_r(path, destination) if File.directory?(path)
      end
      FileUtils.rm_f(File.join(destination, "imageformats", "libqpdf.so"))
    end

    def install_linux_translations(stage, qt)
      source = qt["QT_INSTALL_TRANSLATIONS"]
      return unless source && File.directory?(source)

      destination = File.join(stage, "translations")
      translations = LINUX_TRANSLATION_GLOBS.flat_map { |glob| Dir[File.join(source, glob)] }.uniq.sort
      return if translations.empty?

      FileUtils.mkdir_p(destination)
      FileUtils.cp(translations, destination)
    end

    def install_linux_libraries(stage)
      destination = File.join(stage, "lib")
      FileUtils.mkdir_p(destination)
      queue = [File.join(stage, "bin", "zui-host")]
      queue.concat(Dir[File.join(stage, "{qml,plugins}", "**", "*.so*")])
      inspected = {}
      copied = {}
      until queue.empty?
        binary = queue.shift
        next if inspected[binary]
        inspected[binary] = true

        linux_private_dependencies(binary).each do |library|
          name = File.basename(library)
          next if copied[name]

          installed = File.join(destination, name)
          FileUtils.cp(library, installed)
          copied[name] = true
          queue << installed
        end
      end
    end

    def linux_private_dependencies(binary)
      result = Command.run(["ldd", binary], timeout: 30, max_output_bytes: 2_000_000)
      raise ArgumentError, "could not inspect Linux dependencies for #{binary}: #{result.stderr}" unless result.success?

      result.stdout.each_line.filter_map do |line|
        path = line[/=>\s+(\/\S+)/, 1] || line[/^\s*(\/\S+)/, 1]
        name = File.basename(path.to_s)
        path if path && name.start_with?(*LINUX_PRIVATE_LIBRARY_PREFIXES) && File.file?(path)
      end.uniq
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
        QT_VERSION QT_INSTALL_PLUGINS QT_INSTALL_QML QT_INSTALL_TRANSLATIONS
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
