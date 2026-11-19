# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "tmpdir"
require_relative "client_packager"
require_relative "macos_bundle_seal"
require_relative "macos_qml_payload"

module Zui
  # Internal CI/release builder. It is deliberately not used by `zui configure`.
  class ClientBuilder
    # Bumped when the shape of a cached deployment changes, so an entry written
    # by an older build is ignored rather than misread.
    CACHE_LAYOUT_VERSION = 1

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
      wayland-shell-integration
      xcbglintegrations
    ].freeze
    LINUX_TRANSLATION_GLOBS = %w[
      qtbase_*.qm qtdeclarative_*.qm qtmultimedia_*.qm qtquickcontrols2_*.qm
    ].freeze
    # Qt's FFmpeg backend is loaded at runtime, so its codec libraries are not
    # reachable from the host executable. Keep the direct FFmpeg ABI alongside
    # Qt just like the Qt and ICU libraries; otherwise a system FFmpeg upgrade
    # can leave an already-installed Zui client unable to play media.
    LINUX_PRIVATE_LIBRARY_PREFIXES = %w[
      libQt6 libicu libavcodec libavdevice libavfilter libavformat libavutil libpostproc
      libswresample libswscale
    ].freeze
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

    # A client build takes minutes, so it says where they went. Nobody waiting
    # on one wants to guess, and the numbers are the only way to tell a slow
    # compile from a slow deployment.
    def phase(name)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      warn format("zui client: %-22s %7.1fs", name, elapsed)
      result
    end

    def build!(output:)
      Dir.mktmpdir("zui-client-build-") do |temporary|
        build = File.join(temporary, "build")
        stage = File.join(temporary, "stage")
        qml_scan_root = File.join(temporary, "qml-scan")
        phase("install qml") { Runtime.install_qml(qml_scan_root, framework_root: @framework_root) }
        cmake = command!("cmake")
        phase("cmake configure") do
          run!([cmake, "-S", File.join(@framework_root, "native"), "-B", build,
                "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_PREFIX=#{stage}",
                "-DZUI_QML_SCAN_ROOT=#{qml_scan_root}"], timeout: 240)
        end
        phase("cmake build") { run!([cmake, "--build", build, "--config", "Release", "--parallel"], timeout: 900) }

        qt = qt_installation
        key = deployment_key(qt, qml_scan_root)
        restored = phase("restore deployed qt") { restore_deployment(stage, build, key) }
        unless restored
          phase("cmake install") { run!([cmake, "--install", build, "--config", "Release"], timeout: 900) }
          phase("catalog runtime") { install_catalog_runtime(stage, qt) }
          phase("save deployed qt") { save_deployment(stage, key) }
        end
        phase("package") do
          ClientPackager.new(
            platform: @platform, source_date_epoch: @environment["SOURCE_DATE_EPOCH"]
          ).package(
            source: stage,
            output:,
            executable: executable_relative_path,
            qt_version: qt.fetch("QT_VERSION")
          )
        end
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
        plugin_names = File.foreach(qmldir, encoding: "UTF-8").filter_map do |line|
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
      MacOSQmlPayload.deduplicate!(stage)
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

    # Deploying Qt is 92% of a client build — 322 of 351 seconds on macOS, where
    # `cmake --install` runs macdeployqt and copies ~140 MB of frameworks.
    # Compiling the client itself is 2.4 seconds. So the thing worth keeping
    # between builds is the deployed tree, not the object files.
    #
    # The payload is everything the deployment produced except our own
    # executable, which is rebuilt every time and dropped back in. A cache hit
    # therefore still compiles, and still produces a client built from the
    # source in front of it.
    def deployment_cache_root
      override = @environment["ZUI_CLIENT_CACHE_DIR"]
      return File.expand_path(override) if override && !override.empty?

      File.join(Client.new(platform: @platform, environment: @environment).cache_root,
                "zui", "client-deployments")
    end

    def deployment_cache_enabled?
      value = @environment["ZUI_CLIENT_CACHE"].to_s
      value.empty? || !%w[0 no off false].include?(value.downcase)
    end

    # Everything that changes what the deployment produces has to be in the
    # key. The QML tree is in it because -qmldir is what decides which QML
    # modules are deployed at all, and native/CMakeLists.txt because it carries
    # the deploy tool's options.
    def deployment_key(qt, qml_scan_root)
      digest = Digest::SHA256.new
      digest << "zui-client-deployment/#{CACHE_LAYOUT_VERSION}\0"
      digest << @platform.id.to_s << "\0"
      %w[QT_VERSION QT_INSTALL_QML QT_INSTALL_PLUGINS QT_INSTALL_TRANSLATIONS].each do |field|
        digest << field << "=" << qt[field].to_s << "\0"
      end
      digest << Digest::SHA256.file(File.join(@framework_root, "native", "CMakeLists.txt")).hexdigest << "\0"
      digest << tree_digest(qml_scan_root) << "\0"
      digest.hexdigest
    end

    def tree_digest(root)
      digest = Digest::SHA256.new
      Dir.glob("**/*", File::FNM_DOTMATCH, base: root).sort.each do |relative|
        path = File.join(root, relative)
        next unless File.file?(path) && !File.symlink?(path)

        digest << relative << "\0" << Digest::SHA256.file(path).hexdigest << "\0"
      end
      digest.hexdigest
    end

    def deployment_entry(key) = File.join(deployment_cache_root, key)

    def restore_deployment(stage, build, key)
      return false unless deployment_cache_enabled?

      entry = deployment_entry(key)
      manifest_path = File.join(entry, "manifest.json")
      payload = File.join(entry, "payload.tar")
      return false unless File.file?(manifest_path) && File.file?(payload)

      manifest = JSON.parse(File.read(manifest_path, encoding: "UTF-8"))
      return false unless manifest["layout"] == CACHE_LAYOUT_VERSION

      FileUtils.mkdir_p(stage)
      run!([command!("tar"), "-xpf", payload, "-C", stage], timeout: 900)
      # Every packaged client is checked for the forbidden browser payload, and
      # that has to stay true of one assembled from a cache. The entry was
      # purged when it was written, so this only fires on a cache that has been
      # corrupted or tampered with — which is exactly when it should.
      purge_browser_payload!(stage)
      install_built_executable(build, stage, manifest)
      true
    rescue ArgumentError, JSON::ParserError, Errno::ENOENT => error
      # A cache that cannot be trusted is not worth a failed build. Fall back
      # to deploying, which also replaces the entry.
      warn "zui client: ignoring the cached Qt deployment (#{error.message})"
      FileUtils.rm_rf(stage)
      false
    end

    def save_deployment(stage, key)
      return unless deployment_cache_enabled?

      executable = File.join(stage, executable_relative_path)
      raise ArgumentError, "the deployment produced no executable: #{executable}" unless File.file?(executable)

      manifest = {
        "layout" => CACHE_LAYOUT_VERSION,
        "platform" => @platform.id.to_s,
        "executable" => executable_relative_path,
        "rpaths" => executable_rpaths(executable)
      }

      entry = deployment_entry(key)
      FileUtils.mkdir_p(File.dirname(entry))
      staging = "#{entry}.tmp-#{Process.pid}"
      FileUtils.rm_rf(staging)
      FileUtils.mkdir_p(staging)
      begin
        # Our own executable is left out: it is rebuilt every time, and keeping
        # it would hand back a binary that did not come from this source tree.
        run!([command!("tar"), "-cpf", File.join(staging, "payload.tar"),
              "-C", stage, "--exclude", "./#{executable_relative_path}", "."], timeout: 900)
        File.write(File.join(staging, "manifest.json"), "#{JSON.pretty_generate(manifest)}\n")
        FileUtils.rm_rf(entry)
        File.rename(staging, entry)
      ensure
        FileUtils.rm_rf(staging)
      end
    rescue ArgumentError, SystemCallError => error
      # The client is already built. A cache that cannot be written is a
      # slower next build, not a failed this one.
      warn "zui client: could not keep the deployed Qt payload (#{error.message})"
    end

    def install_built_executable(build, stage, manifest)
      source = built_executable(build)
      destination = File.join(stage, executable_relative_path)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(source, destination)
      FileUtils.chmod(0o755, destination)
      restore_executable_rpaths(destination, Array(manifest["rpaths"]))
      reseal_macos_bundle(stage)
    end

    def built_executable(build)
      name = File.basename(executable_relative_path)
      candidates = [
        File.join(build, executable_relative_path),
        File.join(build, name),
        File.join(build, "Release", name)
      ]
      found = candidates.find { |path| File.file?(path) }
      found ||= Dir[File.join(build, "**", name)].sort.find { |path| File.file?(path) }
      raise ArgumentError, "the build produced no #{name} to pair with the cached deployment" unless found

      found
    end

    # macdeployqt adds one load path to the executable, and a freshly compiled
    # one does not have it. The paths are read off the deployed binary when the
    # payload is saved rather than hard-coded, so this keeps working if Qt or
    # CMake change what they add.
    def restore_executable_rpaths(executable, rpaths)
      return if rpaths.empty? || !@platform.macos?

      present = executable_rpaths(executable)
      (rpaths - present).each do |rpath|
        run!([command!("install_name_tool"), "-add_rpath", rpath, executable], timeout: 120)
      end
    end

    def executable_rpaths(executable)
      return [] unless @platform.macos?

      otool = command?("otool")
      return [] unless otool

      result = Command.run([otool, "-l", executable], timeout: 120, max_output_bytes: 32_000_000)
      return [] unless result.success?

      result.stdout.scan(/^\s*path (\S+) \(offset \d+\)$/).flatten.uniq
    end

    # install_name_tool invalidates the signature the linker put on the
    # executable, and macOS refuses to run a binary whose signature does not
    # match it. Sealing the bundle also restores the framework symlinks, which
    # is why this goes through the same code the distribution path uses.
    def reseal_macos_bundle(stage)
      return unless @platform.macos?

      MacOSBundleSeal.seal!(stage)
    end

    def command?(*names)
      command!(*names)
    rescue ArgumentError
      nil
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
