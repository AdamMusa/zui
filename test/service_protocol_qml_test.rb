# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require_relative "../lib/zui"

# Service.qml's protocol arms are plain JavaScript over plain objects, so they
# can be driven directly — no client, no display, no Ruby process. qmltestrunner
# renders offscreen with the software adapter, which makes this the cheapest
# place to pin the protocol's behaviour.
#
# It skips when Qt's test runner is not on hand rather than failing, the same
# way the lite-runtime smoke test skips without ZUI_MRUBY. Point ZUI_QT_ROOT or
# QT_ROOT_DIR at a Qt installation, or put qmltestrunner on PATH, to run it.
class ServiceProtocolQmlTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCENES = Dir[File.join(ROOT, "test", "qml", "tst_*.qml")].sort.freeze

  def test_the_service_protocol_scenes_pass
    runner = qmltestrunner
    skip "qmltestrunner was not found; set ZUI_QT_ROOT or put it on PATH" unless runner

    refute_empty SCENES, "there are no QML scenes to run"

    SCENES.each do |scene|
      output, status = Open3.capture2e(
        {
          "QT_QPA_PLATFORM" => "offscreen",
          "QT_QUICK_BACKEND" => "software",
          # native/main.cpp pins Fusion, and the native styles refuse a
          # customized background, so the scenes have to be run the way the
          # client runs them.
          "QT_QUICK_CONTROLS_STYLE" => "Fusion"
        },
        runner, "-input", scene, chdir: ROOT
      )

      assert status.success?, "#{File.basename(scene)} failed:\n#{output}"
    end
  end

  private

  # The two kinds of Qt location are not interchangeable, and joining "bin"
  # onto both makes one of them silently never match.
  #
  # A *tree* holds many Qt builds and is resolved by version and host name, the
  # way lib/zui/mobile/setup.rb does it — ZUI_QT_ROOT and the checkout's own
  # tmp/Qt. A *prefix* is one Qt build with bin directly inside — ZUI_QT_HOST,
  # and QT_ROOT_DIR / QT_HOST_PATH as install-qt-action sets them in CI.
  #
  # Kept in the same order as the wrapper on #112 so the two do not drift.
  # Whichever of the two lands second should lift this into a shared helper;
  # it is one file on two branches in flight, which is why it is not one yet.
  QT_TREE_VARIABLES = %w[ZUI_QT_ROOT].freeze
  QT_PREFIX_VARIABLES = %w[ZUI_QT_HOST QT_ROOT_DIR QT_HOST_PATH].freeze

  def qmltestrunner
    candidates.find { |path| File.file?(path) && File.executable?(path) }
  end

  def candidates
    found = []
    override = ENV["ZUI_QMLTESTRUNNER"]
    found << override if override && !override.empty?

    QT_TREE_VARIABLES.each { |variable| found.concat(within_tree(ENV[variable])) }
    found.concat(within_tree(File.join(ROOT, "tmp", "Qt")))
    QT_PREFIX_VARIABLES.each { |variable| found.concat(within_prefix(ENV[variable])) }

    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
      found << File.join(directory, "qmltestrunner") unless directory.empty?
    end
    found
  end

  def within_tree(root)
    return [] if root.nil? || root.empty?

    Dir[File.join(root, "*", "*", "bin", "qmltestrunner")].sort.reverse +
      Dir[File.join(root, "*", "*", "libexec", "qmltestrunner")].sort.reverse
  end

  def within_prefix(root)
    return [] if root.nil? || root.empty?

    [File.join(root, "bin", "qmltestrunner"), File.join(root, "libexec", "qmltestrunner")]
  end
end
