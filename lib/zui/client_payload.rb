# frozen_string_literal: true

require "json"

module Zui
  # Which Qt QML modules the released desktop client carries.
  #
  # Linking a Qt module is not enough for a component to work: the native client is a curated
  # payload, and a module that is neither copied into it nor documented as absent produces a
  # component that loads on a developer machine and fails on a released client. The release audit
  # (`scripts/audit_client.rb`) and the client builder read this one description instead of keeping
  # their own copies of it, and `test/client_payload_test.rb` fails when the framework imports a
  # module that is neither carried nor explained.
  module ClientPayload
    # Top-level directories the client always carries, whether or not an adapter names them: Qt
    # resolves `QML` and parts of `QtQml` itself. Everything else is derived from what the
    # component adapters import, so registering a component is what makes its module ship.
    BASE_ROOTS = %w[QML QtQml].freeze
    # Directories to copy for the Linux client. Kept for the release builder's published contract;
    # `qml_roots` is the derived list a build actually uses.
    QML_ROOTS = %w[
      QML Qt QtCore QtLocation QtMultimedia QtNetwork QtPositioning QtQml QtQuick QtQuick3D
      QtSensors QtTextToSpeech QtWebSockets
    ].freeze
    # Paths below those roots that are dropped again, because nothing in the framework imports them
    # and they are large, platform specific or development tooling.
    QML_EXCLUSIONS = %w[
      Qt/labs/StyleKit Qt/labs/animation Qt/labs/settings Qt/labs/sharedimage Qt/labs/synchronizer
      Qt/labs/wavefrontmesh Qt/test QtQuick/Controls/FluentWinUI3 QtQuick/Controls/Imagine
      QtQuick/Controls/Material QtQuick/Controls/Universal QtQuick/Controls/designer QtQuick/LocalStorage
      QtQuick/Timeline QtQuick/tooling QtQuick3D/Effects QtQuick3D/Helpers
      QtQuick3D/MaterialEditor QtQuick3D/ParticleEffects QtQuick3D/Particles3D QtQuick3D/SpatialAudio
      QtQuick3D/Xr QtQuick3D/designer QtQuick3D/lightmapviewer QtQml/XmlListModel
    ].freeze
    # Payload that must never reach a released client, whatever imports it. The release audit
    # rejects an archive that contains any of it.
    FORBIDDEN = {
      "QtWebEngine" => "a browser engine is far larger than the whole client budget",
      "QtWebChannel" => "only reachable through QtWebEngine",
      "Qt5Compat" => "nothing in the framework imports a Qt 5 compatibility module; a component " \
                     "that needs one has to add Qt5Compat to QML_ROOTS and drop this entry",
      "Quickshell" => "a third-party shell toolkit the framework must not depend on",
      "SddmComponents" => "a display-manager theme toolkit that no client needs"
    }.freeze
    # Library and plugin names that belong to payload the client must not carry. Qt names its
    # libraries after the module rather than after the QML module, so they are listed separately.
    #
    # Qt Positioning used to be rejected here as a "browser-only dependency", because Qt WebEngine
    # pulls it in for the geolocation web API. The dependency only runs that way round: dropping
    # Positioning from this list cannot bring WebEngine back, while keeping it made every
    # positioning and map component unloadable on a released client.
    FORBIDDEN_LIBRARIES = %w[Qt6WebEngine Qt6WebChannel].freeze
    FORBIDDEN_FILES = %w[qtwebengine qwebengine webchannel].freeze
    # Modules a client build may be assembled without. Everything a registered component imports is
    # required by default, because a client that omits it produces a component that cannot load -
    # the silent fallback the framework forbids. A module is optional only when its components
    # probe for it and report a component error when it is absent, which is what
    # Support/ModelView3dScene.qml does behind a Loader for Qt Quick 3D.
    #
    # This is the property a build reads; it is not for a track to decide case by case in the
    # builder.
    OPTIONAL = {
      "QtQuick3D" => "Support/ModelView3dScene.qml loads behind a Loader and model_view_3d reports " \
                     "qtquick3d_unavailable when the module is absent",
      "QtQuick3D.AssetUtils" => "loaded with QtQuick3D by the same probe"
    }.freeze
    # Where the measured payload cost of each root is recorded, so the cost of adding a module is
    # visible in review rather than discovered when the release archive exceeds its budget.
    BUDGET_PATH = File.expand_path("../../native/qt-payload-budget.json", __dir__)
    # Qt QML modules the framework imports although the desktop client does not carry them, with
    # the reason. A component built on one of them reports a missing-module error on the desktop
    # instead of silently rendering something else, and `test/client_payload_test.rb` names the
    # components affected so the trade is visible rather than discovered by a user.
    UNSUPPORTED = {
      "QtWebView" => "Qt builds QtWebView for iOS, Android, macOS and Windows only; a Linux " \
                     "desktop client has no platform web view to embed"
    }.freeze

    class << self
      # The Qt QML modules each registered component needs, as { component => [module] }, read
      # from its adapter and the shared support files that adapter loads.
      def component_modules(framework_root: FRAMEWORK_ROOT, components: COMPONENTS)
        builtins = File.join(framework_root, "Components", "Builtins")
        components.keys.to_h do |component|
          adapter = component.to_s.split("_").map(&:capitalize).join
          [component, imports_of(File.join(builtins, "#{adapter}.qml"), builtins)]
        end
      end

      # Top-level QML directories the client has to carry: the ones Qt resolves itself plus the
      # first path segment of every module a registered component needs. Registering a component
      # is therefore what makes its Qt module ship.
      def qml_roots(framework_root: FRAMEWORK_ROOT)
        @qml_roots ||= {}
        @qml_roots[framework_root] ||= begin
          required = component_modules(framework_root:).values.flatten.uniq
                                                       .reject { |name| UNSUPPORTED.key?(name) || forbidden?(name) }
          (BASE_ROOTS + required.map { |name| name.split(".").first }).uniq.sort.freeze
        end
      end

      # Does the client payload carry this Qt QML module?
      def ships?(qml_module, framework_root: FRAMEWORK_ROOT)
        path = qml_module.to_s.tr(".", "/")
        return false unless qml_roots(framework_root:).include?(path.split("/").first)

        QML_EXCLUSIONS.none? { |excluded| path == excluded || path.start_with?("#{excluded}/") }
      end

      # Registered components whose Qt module the client neither carries nor documents as absent.
      # Each one would work in a development tree and fail to load for a user.
      def unshipped_components(framework_root: FRAMEWORK_ROOT)
        component_modules(framework_root:).each_with_object({}) do |(component, modules), unshipped|
          missing = modules.reject do |name|
            ships?(name, framework_root:) || UNSUPPORTED.key?(name) || !qt_module?(name)
          end
          unshipped[component] = missing unless missing.empty?
        end
      end

      # Registered components that depend on a module the client documents as absent, so the
      # component reports a missing-module error there.
      def unsupported_components(framework_root: FRAMEWORK_ROOT)
        component_modules(framework_root:).each_with_object({}) do |(component, modules), affected|
          reasons = modules.select { |name| UNSUPPORTED.key?(name) }
          affected[component] = reasons unless reasons.empty?
        end
      end

      def qt_module?(qml_module) = qml_module.to_s.match?(/\A(?:QML|Qt)/)

      # Is a build allowed to continue without this module?
      def optional?(qml_module) = OPTIONAL.key?(qml_module.to_s)

      # Which registered components need a module, for a build error that names them.
      def components_needing(qml_module, framework_root: FRAMEWORK_ROOT)
        component_modules(framework_root:).select { |_name, modules| modules.include?(qml_module.to_s) }
                                          .keys.sort
      end

      # The modules a root carries, so a cost or a failure can be reported per registered module
      # rather than per directory.
      def modules_in_root(root, framework_root: FRAMEWORK_ROOT)
        component_modules(framework_root:).values.flatten.uniq
                                          .select { |name| name.split(".").first == root }.sort
      end

      # The recorded payload cost: what the client carries today, and the budget it has to stay in.
      def budget
        @budget ||= JSON.parse(File.read(BUDGET_PATH))
      end

      def budget_bytes = budget.fetch("budget_bytes")

      def recorded_bytes = budget.fetch("roots").values.sum

      # Measures what `install_linux_qml` would copy for each root of an installed Qt tree: the
      # module directories, minus the paths the client drops again.
      def measure(qt_qml_root, framework_root: FRAMEWORK_ROOT)
        qml_roots(framework_root:).to_h do |root|
          directory = File.join(qt_qml_root, root)
          bytes = Dir[File.join(directory, "**", "*")].sum do |path|
            next 0 unless File.file?(path) && !File.symlink?(path)
            # A macOS SDK ships a debug variant of every plugin; a Linux payload has none, so they
            # are left out to keep the measurement comparable across hosts.
            next 0 if File.basename(path).match?(/_debug\.[A-Za-z]+\z/)

            relative = path.delete_prefix("#{qt_qml_root}/")
            next 0 if QML_EXCLUSIONS.any? { |excluded| relative.start_with?("#{excluded}/") }

            File.size(path)
          end
          [root, bytes]
        end
      end

      # Modules the framework imports that the client neither carries nor documents as absent.
      # Each one is a component that works in development and fails on a released client.
      def unresolved(qml_modules)
        Array(qml_modules).reject do |name|
          ships?(name) || UNSUPPORTED.key?(name) || forbidden?(name)
        end
      end

      # Modules the framework imports that the client refuses to carry at all.
      def conflicting(qml_modules)
        Array(qml_modules).select { |name| forbidden?(name) }
      end

      def forbidden?(qml_module)
        root = qml_module.to_s.split(".").first
        FORBIDDEN.key?(qml_module.to_s) || FORBIDDEN.key?(root)
      end

      # Matches any archive or stage entry that belongs to payload a released client must not
      # carry: the forbidden modules, their libraries and plugins, and the unsupported modules
      # whose presence is a defect rather than dead weight.
      def forbidden_pattern
        @forbidden_pattern ||= begin
          names = (FORBIDDEN.keys + audited_unsupported).map do |name|
            "#{Regexp.escape(name.tr('.', '/'))}[^/]*"
          end
          names += FORBIDDEN_LIBRARIES.map { |name| "(?:lib)?#{Regexp.escape(name)}[^/]*" }
          names += FORBIDDEN_FILES.map { |name| "(?:lib)?#{Regexp.escape(name)}[^/]*" }
          Regexp.new(
            "(?:\\A|/)(?:#{names.join('|')})(?:/|\\z)|(?:\\A|/)qml/org/",
            Regexp::IGNORECASE
          )
        end
      end

      # Unsupported modules whose presence in an archive is a defect rather than dead weight.
      def audited_unsupported = []

      private

      # The Qt modules a QML file imports, following the shared support files it loads, which is
      # how `model_view_3d` reaches Qt Quick 3D through Support/ModelView3dScene.qml.
      def imports_of(path, builtins, seen = [])
        return [] unless File.file?(path) && !seen.include?(path)

        seen << path
        text = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
        modules = text.scan(/^\s*import\s+([A-Z][A-Za-z0-9_.]*)/).flatten.select { |name| qt_module?(name) }
        support = text.scan(%r{(?:Support[./]|["'])([A-Z][A-Za-z0-9_]*)\.qml}).flatten.uniq
        modules + support.flat_map do |name|
          imports_of(File.join(builtins, "Support", "#{name}.qml"), builtins, seen)
        end
      end
    end
  end
end
