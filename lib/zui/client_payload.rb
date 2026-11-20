# frozen_string_literal: true

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
    # Top-level directories of the Qt QML tree the Linux client copies.
    QML_ROOTS = %w[QML Qt QtCore QtMultimedia QtNetwork QtQml QtQuick QtQuick3D].freeze
    # Paths below those roots that are dropped again, because nothing in the framework imports them
    # and they are large, platform specific or development tooling.
    QML_EXCLUSIONS = %w[
      Qt/labs/StyleKit Qt/labs/animation Qt/labs/settings Qt/labs/sharedimage Qt/labs/synchronizer
      Qt/labs/wavefrontmesh Qt/test QtQuick/Controls/FluentWinUI3 QtQuick/Controls/Imagine
      QtQuick/Controls/Material QtQuick/Controls/Universal QtQuick/Controls/designer QtQuick/LocalStorage
      QtQuick/Pdf QtQuick/Timeline QtQuick/tooling QtQuick3D/Effects QtQuick3D/Helpers
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
    FORBIDDEN_LIBRARIES = %w[Qt6WebEngine Qt6WebChannel Qt6Positioning].freeze
    FORBIDDEN_FILES = %w[qtwebengine qwebengine webchannel position].freeze
    # Qt QML modules the framework imports although the desktop client does not carry them. These
    # components exist for iOS and Android; on a desktop client they report a missing-module error
    # rather than silently rendering something else.
    UNSUPPORTED = {
      "QtPositioning" => "device positioning is a mobile capability, and the client audit rejects " \
                         "any positioning payload",
      "QtLocation" => "maps need the positioning module and a geoservices plugin, neither of which " \
                      "the client carries",
      "QtSensors" => "sensor hardware is a mobile capability",
      "QtTextToSpeech" => "speech synthesis is a mobile capability",
      "QtWebView" => "the platform web view is a mobile capability; a desktop client would need a " \
                     "browser engine",
      "QtWebSockets" => "a Qt add-on the client does not carry; web_socket is a mobile capability",
      "QtQuick.Pdf" => "Qt PDF renders through its own module, which the client audit rejects"
    }.freeze

    class << self
      # Does the client payload carry this Qt QML module?
      def ships?(qml_module)
        path = qml_module.to_s.tr(".", "/")
        return false unless QML_ROOTS.include?(path.split("/").first)

        QML_EXCLUSIONS.none? { |excluded| path == excluded || path.start_with?("#{excluded}/") }
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

      # Unsupported modules whose presence in an archive is itself a defect rather than dead
      # weight: they pull in location data or a second rendering stack.
      def audited_unsupported
        %w[QtPositioning QtQuick.Pdf]
      end
    end
  end
end
