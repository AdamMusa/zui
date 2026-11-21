# frozen_string_literal: true

require "json"
require "set"

module Zui
  # Single source of truth for the Qt QML modules a Zui build may link.
  #
  # `native/qt-modules.json` records, for every public Qt QML module, the CMake component that
  # provides it, the QML plugin the Qt import scanner resolves it to, the SDK add-on that installs
  # it, the mobile targets that ship it, and the Android permissions it declares. `native/
  # ZuiQtModules.cmake` reads the same document so a new Qt module becomes linkable on iOS and
  # Android by editing one registry entry instead of six build files.
  module QtModules
    REGISTRY_PATH = File.expand_path("../../native/qt-modules.json", __dir__)
    TARGETS = %w[host ios android].freeze

    class Entry
      ATTRIBUTES = %w[qml_module cmake_component link_target qml_plugin sdk_module targets
                      android_permissions native_initialization unavailable notes].freeze

      attr_reader(*ATTRIBUTES.map(&:to_sym))

      def initialize(data)
        @qml_module = data.fetch("qml_module")
        @cmake_component = data["cmake_component"]
        @link_target = data["link_target"]
        @qml_plugin = data["qml_plugin"]
        @sdk_module = data["sdk_module"]
        @targets = Array(data["targets"]).freeze
        @android_permissions = Array(data["android_permissions"]).freeze
        @native_initialization = data["native_initialization"]
        @unavailable = (data["unavailable"] || {}).freeze
        @notes = data["notes"]
        freeze
      end

      # A module with no link target is pure QML (or ships inside another module's library) and
      # needs no CMake wiring at all.
      def linkable? = !link_target.nil?

      # Modules whose types are registered by the backing library require a C++ call before the
      # QML engine starts; `native/main.cpp` performs it behind the compile definition.
      def native_initialization? = !native_initialization.nil?

      def available_on?(target) = targets.include?(target.to_s)

      def unavailable_reason(target) = unavailable[target.to_s]

      # Add-on SDKs have to be installed by `zui mobile --fix`; base modules ship with qtbase and
      # qtdeclarative and need no add-on.
      def add_on? = !sdk_module.nil?

      def to_h
        ATTRIBUTES.to_h { |name| [name, public_send(name)] }.compact.reject do |_key, value|
          value.respond_to?(:empty?) && value.empty?
        end
      end
    end

    class << self
      def registry_path = REGISTRY_PATH

      def document
        @document ||= JSON.parse(File.read(REGISTRY_PATH)).freeze
      end

      def qt_version = document.fetch("qt_version")

      def all
        @all ||= document.fetch("modules").map { |data| Entry.new(data) }.freeze
      end

      def names = all.map(&:qml_module)

      def [](qml_module) = index[qml_module.to_s]

      def fetch(qml_module)
        self[qml_module] || raise(KeyError, "unregistered Qt QML module: #{qml_module}")
      end

      def registered?(qml_module) = index.key?(qml_module.to_s)

      def for_target(target)
        all.select { |entry| entry.available_on?(target) }
      end

      # Modules that reach a mobile target without any zui wiring beyond the import itself.
      def linkable(target)
        for_target(target).select(&:linkable?)
      end

      def add_on_sdk_modules(target)
        for_target(target).filter_map(&:sdk_module).uniq.sort
      end

      def android_permissions_for(qml_modules)
        Array(qml_modules).flat_map { |name| self[name]&.android_permissions || [] }.uniq.sort
      end

      # Every QML module imported anywhere in the framework QML tree, in import order of appearance.
      def imported_by(root)
        Dir[File.join(root, "**", "*.qml")].sort.each_with_object({}) do |path, imports|
          File.foreach(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "") do |line|
            name = line[/^\s*import\s+([A-Za-z][A-Za-z0-9_.]*)/, 1]
            next unless name

            (imports[name] ||= []) << path
          end
        end
      end

      def reset!
        @document = nil
        @all = nil
        @index = nil
      end

      private

      def index
        @index ||= all.to_h { |entry| [entry.qml_module, entry] }.freeze
      end
    end

    # Rebuilds the registry document from installed Qt SDKs. Used by `rake qt:modules`; the
    # generated document is committed so builds and tests never depend on a local Qt checkout.
    class SdkScan
      # Style implementations, private helpers, designer/test tooling and virtual-keyboard
      # internals are never imported directly by an application.
      INTERNAL = /
        (?:\.impl|\.private|\.tooling)\z | \AQt\.test\. | \AQmlTime\z | \AQtTest\z |
        \AAssets\.Downloader\z | MaterialEditor | TestUtils |
        \AQtQuick\.VirtualKeyboard\.(?:Components|Layouts|Plugins|Styles)
      /x
      # Repositories that ship inside the Qt base package; everything else is an aqt add-on that
      # `Zui::Mobile::Setup` has to install explicitly.
      BASE_REPOSITORIES = %w[
        qtbase qtdeclarative qtimageformats qtshadertools qtsvg qttools qttranslations
      ].freeze
      # Qt repository names that differ from the aqt add-on name used to install them.
      SDK_MODULE_ALIASES = { "qtdatavisualization" => "qtdatavis3d" }.freeze
      # Modules the host shell initializes before the QML engine starts.
      NATIVE_INITIALIZATION = {
        "QtWebView" => "ZUI_USES_WEBVIEW",
        "QtQuick.VirtualKeyboard" => "ZUI_USES_VIRTUAL_KEYBOARD"
      }.freeze
      # Libraries every Qt application links, so their permissions are not module specific.
      UBIQUITOUS_PACKAGES = %w[Qt6Core Qt6Gui Qt6Network Qt6Qml Qt6Quick].freeze
      # Interface libraries a QML plugin always links; they never identify the module itself.
      GENERIC_LINK_TARGET = /
        \A(?:Core|Gui|Network|OpenGL|Svg|Qml|QmlMeta|QmlModels|Quick|EntryPoint\w*|Platform\w*)
        (?:Private)?\z
      /x

      def initialize(roots)
        @roots = roots.transform_keys(&:to_s).transform_values { |path| File.expand_path(path) }
        @host = @roots.fetch("host")
      end

      def document
        {
          "format" => 1,
          "generated_by" => "rake qt:modules",
          "qt_version" => qt_version,
          "targets" => @roots.keys,
          "modules" => modules
        }
      end

      private

      def qt_version
        File.basename(File.expand_path("..", @host))
      end

      def modules
        module_directories(@host).keys.sort.filter_map do |name|
          next if name.match?(INTERNAL)

          entry_for(name)
        end
      end

      def entry_for(name)
        plugin = plugin_for(name)
        targets = @roots.keys.select { |target| module_directories(@roots.fetch(target)).key?(name) }
        component = component_for(plugin, name, targets)
        {
          "qml_module" => name,
          "cmake_component" => component,
          "link_target" => component && "Qt6::#{component}",
          "qml_plugin" => plugin,
          "sdk_module" => sdk_module_for(plugin),
          "targets" => targets,
          "android_permissions" => android_permissions(component),
          "native_initialization" => NATIVE_INITIALIZATION[name]
        }.compact.reject { |_key, value| value.respond_to?(:empty?) && value.empty? }
      end

      def module_directories(root)
        @module_directories ||= {}
        @module_directories[root] ||= Dir[File.join(root, "qml", "**", "qmldir")].filter_map do |path|
          name = read_lines(path).filter_map { |line| line[/^\s*module\s+(\S+)/, 1] }.first
          [name, File.dirname(path)] if name
        end.to_h
      end

      # `qmldir` names the CMake plugin target the Qt import scanner resolves the module to. Shared
      # builds spell the plugin file name with a `plugin` suffix the CMake package does not use, so
      # the `linktarget` line is the reliable identifier.
      def plugin_for(name)
        @roots.each_value do |root|
          directory = module_directories(root)[name]
          next unless directory

          lines = read_lines(File.join(directory, "qmldir"))
          plugin = lines.filter_map { |line| line[/^\s*linktarget\s+Qt6::(\S+)/, 1] }.first
          plugin ||= lines.filter_map { |line| line[/^\s*(?:optional\s+)?plugin\s+(\S+)/, 1] }.first
          return plugin if plugin
        end
        nil
      end

      # A QML plugin links the library that registers the module's types. Everything else on its
      # interface is a generic Qt interface library or another QML plugin (always lower case). The
      # module's own library is the shortest remaining candidate named after the module, and a
      # module with no candidate at all is implemented purely in QML inside its plugin.
      def component_for(plugin, qml_module, targets)
        manifest = plugin_manifest(plugin, "Targets")
        return nil unless manifest

        candidates = manifest.scan(/LINK_ONLY:Qt6::([A-Z0-9]\w+)/).flatten.uniq
                             .grep_v(GENERIC_LINK_TARGET)
                             .filter_map { |name| findable_package(name, targets) }.uniq
        key = qml_module.delete_prefix("Qt").delete(".").downcase
        named = candidates.select { |name| name.downcase.start_with?(key) }
        named.min_by(&:length) || candidates.last
      end

      # Private interface libraries are usually part of their public package rather than a package
      # of their own, and only a component with a CMake package can be named in find_package().
      def findable_package(component, targets)
        [component, component.sub(/Private\z/, "")].uniq.find do |candidate|
          targets.all? do |target|
            File.directory?(File.join(@roots.fetch(target), "lib", "cmake", "Qt6#{candidate}"))
          end
        end
      end

      # Plugin targets record the Qt repository they were built from, which is also the aqt
      # add-on name `zui mobile --fix` installs.
      def sdk_module_for(plugin)
        repository = plugin_manifest(plugin, "Targets")&.slice(/_repo_project_name_lowercase\s+"([^"]+)"/, 1)
        return nil if repository.nil? || BASE_REPOSITORIES.include?(repository)

        SDK_MODULE_ALIASES.fetch(repository, repository)
      end

      def plugin_manifest(plugin, kind)
        return nil unless plugin

        path = plugin_manifests(kind)["qt6#{plugin.downcase}#{kind.downcase}.cmake"]
        path && read_lines(path).join("\n")
      end

      def plugin_manifests(kind)
        @plugin_manifests ||= {}
        # Static builds carry the full plugin interface; the iOS SDK therefore wins over the
        # shared host and Android SDKs, whose plugin targets record no link interface at all.
        @plugin_manifests[kind] ||= %w[host android ios].filter_map { |target| @roots[target] }
                                                        .flat_map do |root|
          Dir[File.join(root, "lib", "cmake", "Qt6Qml", "QmlPlugins", "Qt6*#{kind}.cmake")]
        end.to_h { |path| [File.basename(path).downcase, path] }
      end

      # Qt declares the Android permissions a module needs next to its library, and androiddeployqt
      # inserts them at the manifest's `%%INSERT_PERMISSIONS` marker. Permissions that come from
      # Qt Core, Gui, Network, Qml or Quick are reported for every module, so they are dropped.
      def android_permissions(component)
        root = @roots["android"]
        return [] unless root && component

        (package_closure("Qt6#{component}") - UBIQUITOUS_PACKAGES).flat_map do |package|
          path = Dir[File.join(root, "lib", "#{package}_*-android-dependencies.xml")].first
          next [] unless path

          read_lines(path).join("\n").scan(/permission name="([^"]+)"/).flatten
        end.uniq.sort
      end

      def package_closure(package)
        closure = Set.new
        queue = [package]
        until queue.empty?
          current = queue.shift
          next unless closure.add?(current)

          queue.concat(package_dependencies(current))
        end
        closure.to_a
      end

      def package_dependencies(package)
        root = @roots["android"] || @host
        path = File.join(root, "lib", "cmake", package, "#{package}Dependencies.cmake")
        return [] unless File.file?(path)

        read_lines(path).join("\n").scan(/_target_deps\s+"([^"]*)"/).flatten
                        .join(";").scan(/Qt6\w+/).uniq
      end

      def read_lines(path)
        File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
      end
    end
  end
end
