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

  def qmltestrunner
    candidates = []
    %w[ZUI_QT_ROOT QT_ROOT_DIR QT_HOST_PATH].each do |variable|
      root = ENV[variable]
      next if root.nil? || root.empty?

      candidates << File.join(root, "bin", "qmltestrunner")
      candidates << File.join(root, "libexec", "qmltestrunner")
    end
    candidates.concat(Dir[File.join(ROOT, "tmp", "Qt", "*", "*", "bin", "qmltestrunner")].sort.reverse)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
      next if directory.empty?

      candidates << File.join(directory, "qmltestrunner")
    end

    candidates.find { |path| File.file?(path) && File.executable?(path) }
  end
end
