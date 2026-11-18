# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require_relative "../lib/zui"

# Qt Quick Controls already tracks a press in `down`. An adapter that overrides
# `background` has to paint it, and the adapters on a navigation path did not,
# so pressing a sidebar entry drew nothing at all until the next page finished
# building. No string match on the source can see that a control answers a
# press, so this drives the real adapters with a synthesised mouse event and
# reads the painted pixels back, offscreen, through Qt's own test runner.
class PressedFeedbackTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCENE = File.join(ROOT, "test", "qml", "tst_pressed_feedback.qml")

  # The client pins the Fusion style (native/main.cpp), and the native styles
  # refuse a customized background, so the scene has to agree with it. The
  # software adapter is what lets the offscreen platform rasterize at all.
  ENVIRONMENT = {
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QUICK_BACKEND" => "software",
    "QT_QUICK_CONTROLS_STYLE" => "Fusion"
  }.freeze

  # Kept in step with test/service_protocol_qml_test.rb, which looks the runner
  # up the same way. ZUI_QT_ROOT and tmp/Qt hold a tree of versions and host
  # platforms (lib/zui/mobile/setup.rb resolves them the same way), so they are
  # globbed; QT_ROOT_DIR from install-qt-action and QT_HOST_PATH are already a
  # single Qt prefix.
  def runner
    explicit = ENV["ZUI_QMLTESTRUNNER"].to_s
    return explicit if File.executable?(explicit)

    trees = [ENV["ZUI_QT_ROOT"].to_s, File.join(ROOT, "tmp", "Qt")].reject(&:empty?)
    prefixes = [ENV["ZUI_QT_HOST"].to_s, ENV["QT_ROOT_DIR"].to_s, ENV["QT_HOST_PATH"].to_s].reject(&:empty?)

    candidates = trees.flat_map { |tree| Dir[File.join(tree, "*", "*", "bin", "qmltestrunner")].sort }
    candidates += prefixes.map { |prefix| File.join(prefix, "bin", "qmltestrunner") }
    candidates += ENV["PATH"].to_s.split(File::PATH_SEPARATOR).reject(&:empty?)
                              .map { |dir| File.join(dir, "qmltestrunner") }
    candidates.find { |candidate| File.executable?(candidate) }
  end

  def test_the_pressed_adapters_repaint_while_they_are_held_down
    executable = runner
    skip "qmltestrunner is not installed; set ZUI_QMLTESTRUNNER to run this" unless executable

    output, status = Open3.capture2e(ENVIRONMENT, executable, "-input", SCENE, chdir: ROOT)

    assert status.success?, "pressed-feedback scene failed:\n#{output}"
    assert_match(/\bTotals: \d+ passed, 0 failed/, output, output)
    refute_match(/painted nothing while held down/, output, output)
  end
end
