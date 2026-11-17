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

  # The check that matters: a registered component whose Qt module is not in the shipped payload
  # works in a development tree and cannot load for a user. Six such cases - Qt5Compat,
  # QtQuick/Timeline, QtQml/XmlListModel, QtQuick/Pdf, the QtQuick3D submodules and the whole
  # positioning family - were each found separately before this test existed.
  def test_every_registered_component_ships_the_qt_modules_it_imports
    unshipped = Zui::ClientPayload.unshipped_components

    assert_empty unshipped,
                 "these components import a Qt module the desktop client does not carry: " \
                 "#{unshipped.map { |component, modules| "#{component} (#{modules.join(', ')})" }.join('; ')}. " \
                 "Add the module to the payload, or record in Zui::ClientPayload::UNSUPPORTED why " \
                 "the client cannot ship it."
  end

  # Components the client cannot support have to be few, named and explained, because each one is a
  # component that reports an error instead of rendering on the desktop.
  def test_components_the_client_cannot_support_are_named_with_a_reason
    affected = Zui::ClientPayload.unsupported_components

    assert_equal({ web_view: ["QtWebView"] }, affected)
    assert_equal %w[QtWebView], Zui::ClientPayload::UNSUPPORTED.keys
    assert_includes Zui::ClientPayload::UNSUPPORTED.fetch("QtWebView"), "no platform web view"
  end

  # The release audit enforces its budget on the compressed archive, which only a Linux client
  # build produces, so nobody adding a Qt module could see what it cost. The recorded payload makes
  # the cost visible in review and keeps the total from drifting past the budget across several PRs
  # that cannot see each other.
  def test_the_recorded_payload_stays_within_its_budget
    payload = Zui::ClientPayload
    recorded = payload.budget.fetch("roots")
    total = payload.recorded_bytes

    assert_operator total, :<=, payload.budget_bytes,
                    "the recorded payload is #{(total - payload.budget_bytes) / 1_048_576} MiB over " \
                    "budget; trim a root or raise the budget deliberately"
    assert_equal payload.budget.fetch("total_bytes"), total
    refute_empty payload.budget.fetch("measured_on")
  end

  # A module added to the payload without recording its cost would make the budget meaningless.
  def test_every_root_the_client_carries_has_a_recorded_cost
    unrecorded = Zui::ClientPayload.qml_roots - Zui::ClientPayload.budget.fetch("roots").keys

    assert_empty unrecorded,
                 "#{unrecorded.join(', ')} joined the client payload without a measurement; " \
                 "run `rake qt:payload WRITE=1` with a Qt SDK and commit the result"
  end

  # Required is the default, because a client that omits a module a component needs produces a
  # component that cannot load. Optional is for modules a component probes for.
  def test_module_requirement_is_a_property_of_the_registration
    assert Zui::ClientPayload.optional?("QtQuick3D")
    assert Zui::ClientPayload.optional?("QtQuick3D.AssetUtils")
    refute Zui::ClientPayload.optional?("QtLocation")
    refute Zui::ClientPayload.optional?("QtQuick")
    assert_includes Zui::ClientPayload.components_needing("QtLocation"), :map
    assert_includes Zui::ClientPayload.components_needing("QtQuick3D"), :model_view_3d
    assert_includes Zui::ClientPayload.modules_in_root("QtPositioning"), "QtPositioning"
    Zui::ClientPayload::OPTIONAL.each_value { |reason| refute_empty reason }
  end

  # The payload the builder copies and the payload the registry implies are the same list.
  def test_the_builder_roots_match_the_registered_components
    assert_equal Zui::ClientPayload.qml_roots, Zui::ClientBuilder::LINUX_QML_ROOTS.sort
    assert_equal Zui::ClientPayload.qml_roots, Zui::ClientPayload::QML_ROOTS.sort
  end

  # The modules that were missing from the payload until this PR, as a regression guard.
  def test_the_payload_carries_the_modules_that_were_missing
    %w[QtPositioning QtLocation QtSensors QtTextToSpeech QtTextToSpeech QtWebSockets QtNetwork
       QtQuick.Pdf].each do |qml_module|
      assert Zui::ClientPayload.ships?(qml_module), "#{qml_module} does not reach the client"
      refute_match Zui::ClientPayload.forbidden_pattern, "qml/#{qml_module.tr('.', '/')}/qmldir"
    end
    refute_match Zui::ClientPayload.forbidden_pattern, "lib/libQt6Positioning.so.6"
    refute_match Zui::ClientPayload.forbidden_pattern, "plugins/position/libqtposition_geoclue2.so"
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

  # The deny-list keeps rejecting a browser engine and the third-party toolkits, and no longer
  # rejects the positioning and PDF payload that registered components need.
  def test_the_forbidden_pattern_rejects_browser_payload_only
    %w[
      qml/QtWebEngine/x.qml lib/libQt6WebEngineCore.so.6 qml/QtWebChannel/qmldir
      qml/org/kde/x.qml qml/Qt5Compat/GraphicalEffects/qmldir
      qml/Quickshell/x.qml qml/SddmComponents/x.qml lib/libqwebengineview.so
    ].each do |entry|
      assert_match Zui::ClientPayload.forbidden_pattern, entry
    end

    %w[
      client.json qml/QtQuick/Controls/libqtquickcontrols2plugin.so qml/QtNetwork/qmldir
      qml/QtQuick3D/qmldir lib/libQt6Network.so.6 lib/libQt6Core5Compat.so
      qml/QtQuick/Controls/Material/qmldir qml/QtPositioning/qmldir lib/libQt6Positioning.so.6
      plugins/position/libqtposition_geoclue2.so qml/QtQuick/Pdf/qmldir
      plugins/geoservices/libqtgeoservices_osm.so
    ].each do |entry|
      refute_match Zui::ClientPayload.forbidden_pattern, entry
    end
  end
end
