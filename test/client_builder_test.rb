# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "../lib/zui/client_builder"

class ClientBuilderTest < Minitest::Test
  def test_purges_webengine_and_its_browser_only_dependencies
    Dir.mktmpdir do |stage|
      forbidden = [
        "qml/QtWebEngine/libqtwebenginequickplugin.so",
        "qml/QtWebChannel/qmldir",
        "qml/QtPositioning/qmldir",
        "lib/libQt6WebEngineCore.so.6",
        "lib/libQt6WebChannel.so.6",
        "plugins/designer/libqwebengineview.so",
        "plugins/position/libqtposition_geoclue2.so",
        "translations/qtwebengine_locales/en-US.pak"
      ]
      forbidden.each do |relative|
        path = File.join(stage, relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "browser payload")
      end
      desktop_library = File.join(stage, "lib", "libQt6Quick.so.6")
      File.write(desktop_library, "desktop UI")

      builder = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      builder.send(:purge_browser_payload!, stage)

      forbidden.each { |relative| refute File.exist?(File.join(stage, relative)) }
      assert File.file?(desktop_library)
    end
  end
end
