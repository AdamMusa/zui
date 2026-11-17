# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "../lib/zui/client_builder"

class ClientBuilderTest < Minitest::Test
  def test_macos_qml_plugins_have_one_canonical_runtime_copy
    Dir.mktmpdir do |stage|
      contents = File.join(stage, "zui-host.app", "Contents")
      qml = File.join(contents, "Resources", "qml", "QtQuick")
      duplicate = File.join(contents, "PlugIns", "quick", "libqtquick2plugin.dylib")
      FileUtils.mkdir_p([qml, File.dirname(duplicate)])
      File.write(File.join(qml, "qmldir"), "module QtQuick\nplugin qtquick2plugin\n")
      File.binwrite(duplicate, "qml plugin")
      builder = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :macos, arch: :arm64))

      builder.send(:install_macos_qml_plugins, stage)

      assert_equal "qml plugin", File.binread(File.join(qml, "libqtquick2plugin.dylib"))
      refute File.exist?(File.join(contents, "PlugIns", "quick"))
    end
  end

  # The purge exists to keep a browser engine out of the client. It used to take Qt Positioning
  # with it, because Qt WebEngine pulls Positioning in for the geolocation web API - but the
  # dependency only runs that way round, and removing Positioning left every positioning and map
  # component unable to load on a released client.
  def test_purges_webengine_payload_and_keeps_the_modules_components_need
    Dir.mktmpdir do |stage|
      forbidden = [
        "qml/QtWebEngine/libqtwebenginequickplugin.so",
        "qml/QtWebChannel/qmldir",
        "lib/libQt6WebEngineCore.so.6",
        "lib/libQt6WebChannel.so.6",
        "plugins/designer/libqwebengineview.so",
        "translations/qtwebengine_locales/en-US.pak"
      ]
      required = [
        "qml/QtPositioning/qmldir",
        "qml/QtLocation/qmldir",
        "qml/QtQuick/Pdf/qmldir",
        "lib/libQt6Positioning.so.6",
        "plugins/position/libqtposition_geoclue2.so",
        "plugins/geoservices/libqtgeoservices_osm.so",
        "lib/libQt6Quick.so.6"
      ]
      (forbidden + required).each do |relative|
        path = File.join(stage, relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "payload")
      end

      builder = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      builder.send(:purge_browser_payload!, stage)

      forbidden.each { |relative| refute File.exist?(File.join(stage, relative)), relative }
      required.each { |relative| assert File.file?(File.join(stage, relative)), relative }
    end
  end

  def test_linux_qml_payload_contains_only_catalog_roots
    Dir.mktmpdir do |directory|
      qml = File.join(directory, "qt", "qml")
      stage = File.join(directory, "stage")
      Zui::ClientPayload.qml_roots.each do |root|
        path = File.join(qml, root)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "catalog-marker"), root)
      end
      Zui::ClientBuilder::LINUX_QML_EXCLUSIONS.each do |relative|
        path = File.join(qml, relative)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "unused-marker"), relative)
      end
      FileUtils.mkdir_p(File.join(qml, "UnrelatedDesktopModule"))
      File.write(File.join(qml, "UnrelatedDesktopModule", "unused"), "unused")

      builder.send(:install_linux_qml, stage, "QT_INSTALL_QML" => qml)

      Zui::ClientPayload.qml_roots.each do |root|
        assert File.file?(File.join(stage, "qml", root, "catalog-marker"))
      end
      Zui::ClientBuilder::LINUX_QML_EXCLUSIONS.each do |relative|
        refute File.exist?(File.join(stage, "qml", relative))
      end
      refute File.exist?(File.join(stage, "qml", "UnrelatedDesktopModule"))
    end
  end

  def test_linux_plugin_payload_excludes_designer_and_pdf_plugins
    Dir.mktmpdir do |directory|
      plugins = File.join(directory, "qt", "plugins")
      stage = File.join(directory, "stage")
      Zui::ClientBuilder::LINUX_PLUGIN_DIRECTORIES.each do |name|
        path = File.join(plugins, name)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "catalog-plugin.so"), name)
      end
      File.write(File.join(plugins, "imageformats", "libqpdf.so"), "pdf")
      FileUtils.mkdir_p(File.join(plugins, "designer"))
      File.write(File.join(plugins, "designer", "unused.so"), "designer")

      builder.send(:install_linux_plugins, stage, "QT_INSTALL_PLUGINS" => plugins)

      assert File.file?(File.join(stage, "plugins", "platforms", "catalog-plugin.so"))
      assert File.file?(File.join(stage, "plugins", "multimedia", "catalog-plugin.so"))
      assert File.file?(File.join(stage, "plugins", "wayland-shell-integration", "catalog-plugin.so"))
      refute File.exist?(File.join(stage, "plugins", "imageformats", "libqpdf.so"))
      refute File.exist?(File.join(stage, "plugins", "designer"))
    end
  end

  def test_linux_runtime_carries_the_direct_ffmpeg_abi
    prefixes = Zui::ClientBuilder::LINUX_PRIVATE_LIBRARY_PREFIXES

    %w[libavcodec libavformat libavutil libswresample libswscale].each do |name|
      assert_includes prefixes, name
    end
  end

  private

  def builder
    @builder ||= Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
  end
end
