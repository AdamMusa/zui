# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"
require_relative "../lib/zui/client_payload"
require_relative "../lib/zui/client_builder"

# Linking a Qt module is not the last gate a component passes. The released desktop client carries
# a curated QML payload, so a component whose adapter imports a module the payload does not carry
# works on a developer machine and fails on the installed client, and the release audit rejects an
# archive that carries payload the client must not ship. Both lists live in Zui::ClientPayload and
# this test keeps them in step with what the framework actually imports.
class ClientPayloadTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def framework_imports
    @framework_imports ||= begin
      files = Dir[File.join(ROOT, "*.qml")] +
              Dir[File.join(ROOT, "{Components,Controls,Theme}", "**", "*.qml")]
      files.flat_map do |path|
        File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "").filter_map do |line|
          line[/\A\s*import\s+([A-Z][A-Za-z0-9_.]*)/, 1]
        end
      end.uniq.grep(/\A(?:QML|Qt)/).sort
    end
  end

  def test_every_qt_module_the_framework_imports_is_carried_or_explained
    unresolved = Zui::ClientPayload.unresolved(framework_imports)

    refute_empty framework_imports
    assert_empty unresolved,
                 "#{unresolved.join(', ')} reach a mobile build but the desktop client neither " \
                 "carries nor documents them: add the root to Zui::ClientPayload::QML_ROOTS or " \
                 "record why the client cannot ship it in UNSUPPORTED"
  end

  # A module that the framework imports and the audit forbids is worse than an absent one: the
  # release build fails instead of the component.
  def test_no_imported_module_is_forbidden_payload
    conflicting = Zui::ClientPayload.conflicting(framework_imports)

    assert_empty conflicting,
                 "#{conflicting.join(', ')} is imported by the framework and rejected by the " \
                 "release audit; one of the two has to change"
  end

  def test_the_payload_description_is_consistent
    carried = framework_imports.select { |name| Zui::ClientPayload.ships?(name) }

    refute_empty carried
    assert_empty carried & Zui::ClientPayload::UNSUPPORTED.keys
    Zui::ClientPayload::UNSUPPORTED.each do |name, reason|
      refute Zui::ClientPayload.ships?(name), "#{name} is documented as absent but is carried"
      refute_empty reason.to_s
    end
    Zui::ClientPayload::FORBIDDEN.each_value { |reason| refute_empty reason.to_s }
  end

  # QtNetwork carries the QML singleton that network_status reads, and nothing about it is mobile
  # specific, so the client has to carry it.
  def test_the_client_carries_the_modules_its_desktop_components_need
    assert Zui::ClientPayload.ships?("QtNetwork")
    assert Zui::ClientPayload.ships?("QtQuick.Effects")
    assert Zui::ClientPayload.ships?("QtQuick.Particles")
    assert Zui::ClientPayload.ships?("Qt.labs.lottieqt")
    refute Zui::ClientPayload.ships?("QtQuick.LocalStorage")
  end

  def test_the_builder_and_the_release_audit_share_one_description
    audit = File.read(File.join(ROOT, "scripts", "audit_client.rb"))

    assert_equal Zui::ClientPayload::QML_ROOTS, Zui::ClientBuilder::LINUX_QML_ROOTS
    assert_equal Zui::ClientPayload::QML_EXCLUSIONS, Zui::ClientBuilder::LINUX_QML_EXCLUSIONS
    assert_equal Zui::ClientPayload.forbidden_pattern, Zui::ClientBuilder::BROWSER_PAYLOAD_PATTERN
    assert_includes audit, "Zui::ClientPayload.forbidden_pattern"
    refute_includes audit, "QtWebEngine"
  end

  def test_the_forbidden_pattern_still_rejects_what_it_always_rejected
    %w[
      qml/QtWebEngine/x.qml lib/libQt6WebEngineCore.so.6 qml/QtWebChannel/qmldir
      plugins/position/libqtposition_geoclue2.so qml/QtPositioning/qmldir lib/libQt6Positioning.so.6
      qml/QtQuick/Pdf/qmldir qml/org/kde/x.qml qml/Qt5Compat/GraphicalEffects/qmldir
      qml/Quickshell/x.qml qml/SddmComponents/x.qml lib/libqwebengineview.so
    ].each do |entry|
      assert_match Zui::ClientPayload.forbidden_pattern, entry
    end

    %w[
      client.json qml/QtQuick/Controls/libqtquickcontrols2plugin.so qml/QtNetwork/qmldir
      qml/QtQuick3D/qmldir lib/libQt6Network.so.6 lib/libQt6Core5Compat.so
      qml/QtQuick/Controls/Material/qmldir
    ].each do |entry|
      refute_match Zui::ClientPayload.forbidden_pattern, entry
    end
  end
end
