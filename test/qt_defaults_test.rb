# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"
require_relative "../lib/zui/qt_defaults"

# Qt's documented defaults and Qt's real defaults disagree, and the SDK's type descriptions carry
# no defaults at all, so an adapter's fallback can only be checked against a live QML engine. The
# parsing half runs anywhere; the engine half runs where a Qt SDK is installed.
class QtDefaultsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  PARTICLES = File.join(ROOT, "Components", "Builtins", "ParticleSystem.qml")

  def defaults(qt_root: "/nonexistent")
    Zui::QtDefaults.new(qt_root:, framework_root: ROOT)
  end

  def installed_qt_root
    [ENV["ZUI_QT_HOST"], File.join(ROOT, "tmp", "Qt", Zui::Mobile::Setup::QT_VERSION, "macos")]
      .compact.find { |path| File.executable?(File.join(path, "bin", "qml")) }
  end

  def assignments
    @assignments ||= defaults.assignments([PARTICLES])
  end

  def find(element, property)
    assignments.select { |a| a.element == element && a.qt_property == property }
  end

  # The framework writes QML compactly, with several properties and nested elements on one line, so
  # a property has to be attributed to the element that encloses it rather than to the file.
  def test_assignments_are_attributed_to_the_enclosing_element
    refute_empty assignments
    assert_equal %w[AngleDirection Emitter Gravity ImageParticle Item ParticleSystem Turbulence],
                 assignments.map(&:element).uniq.sort

    emit_rate = find("Emitter", "emitRate").first

    assert_equal "emit_rate", emit_rate.zui_property
    assert_equal "40", emit_rate.fallback
  end

  # `velocity: AngleDirection { angle: … }` declares an element inside a property value; its
  # properties belong to it, not to the Emitter around it.
  def test_elements_declared_inside_a_property_value_own_their_properties
    assert_empty find("Emitter", "magnitude")
    refute_empty find("AngleDirection", "magnitude")
    assert_equal %w[acceleration velocity],
                 find("AngleDirection", "magnitude").map(&:zui_property).sort
  end

  def test_geometry_properties_are_separated_from_behaviour
    geometry = assignments.select(&:geometry?).map(&:qt_property)

    assert_includes geometry, "implicitWidth"
    refute_includes geometry, "emitRate"
  end

  # A value that reads two properties - Math.max of a width and a minimum, say - cannot attribute
  # its fallback to one of them, so those assignments say so instead of claiming a default.
  def test_values_that_read_several_properties_are_marked_ambiguous
    ambiguous = defaults.assignments(defaults.adapter_paths).select(&:ambiguous)

    refute_empty ambiguous
    assert_operator ambiguous.length, :<, 200
    assert(ambiguous.all? { |assignment| assignment.fallback })
  end

  def test_the_adapter_filter_selects_by_file_name
    assert_equal [PARTICLES], defaults.adapter_paths("particlesystem")
    assert_includes defaults.adapter_paths, PARTICLES
    assert_operator defaults.adapter_paths.length, :>, 250
  end

  # The engine half. Gravity reports magnitude -10 and angle 90 although its documentation gives no
  # default at all, which is the divergence that made this check worth having.
  def test_real_qt_defaults_are_read_from_a_live_engine
    root = installed_qt_root
    skip "no Qt #{Zui::Mobile::Setup::QT_VERSION} SDK with a qml runtime installed" unless root

    probe = defaults(qt_root: root)
    findings = probe.findings([PARTICLES]).to_h { |f| ["#{f.element}.#{f.qt_property}", f] }

    assert_empty probe.warnings
    assert_equal(-10, findings.fetch("Gravity.magnitude").qt_default)
    assert_equal 90, findings.fetch("Gravity.angle").qt_default
    assert_equal 10, findings.fetch("Emitter.emitRate").qt_default
    assert findings.fetch("Gravity.magnitude").differs?, "zui defaults gravity off, Qt does not"
    refute findings.fetch("Gravity.angle").differs?
  end
end
