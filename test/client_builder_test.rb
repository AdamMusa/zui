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

  def test_linux_qml_payload_contains_only_catalog_roots
    Dir.mktmpdir do |directory|
      qml = File.join(directory, "qt", "qml")
      stage = File.join(directory, "stage")
      Zui::ClientBuilder::LINUX_QML_ROOTS.each do |root|
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

      Zui::ClientBuilder::LINUX_QML_ROOTS.each do |root|
        assert File.file?(File.join(stage, "qml", root, "catalog-marker"))
      end
      Zui::ClientBuilder::LINUX_QML_EXCLUSIONS.each do |relative|
        refute File.exist?(File.join(stage, "qml", relative))
      end
      refute File.exist?(File.join(stage, "qml", "UnrelatedDesktopModule"))
    end
  end

  def test_linux_qml_payload_requires_the_chart_and_graph_modules
    Dir.mktmpdir do |directory|
      qml = File.join(directory, "qt", "qml")
      stage = File.join(directory, "stage")
      Zui::ClientBuilder::LINUX_QML_ROOTS.each do |root|
        FileUtils.mkdir_p(File.join(qml, root))
      end
      charts = File.join(qml, "QtCharts")
      FileUtils.mkdir_p(File.join(charts, "designer"))
      File.write(File.join(charts, "qmldir"), "module QtCharts\n")

      builder.send(:install_linux_qml, stage, "QT_INSTALL_QML" => qml)

      assert_includes Zui::ClientBuilder::LINUX_QML_ROOTS, "QtCharts"
      assert_includes Zui::ClientBuilder::LINUX_QML_ROOTS, "QtGraphs"
      assert File.file?(File.join(stage, "qml", "QtCharts", "qmldir"))
      # Designer tooling is excluded like QtQuick3D's.
      refute File.exist?(File.join(stage, "qml", "QtCharts", "designer"))
    end
  end

  def test_linux_qml_payload_refuses_a_qt_build_without_the_chart_module
    Dir.mktmpdir do |directory|
      qml = File.join(directory, "qt", "qml")
      stage = File.join(directory, "stage")
      (Zui::ClientBuilder::LINUX_QML_ROOTS - %w[QtCharts]).each do |root|
        FileUtils.mkdir_p(File.join(qml, root))
      end

      error = assert_raises(ArgumentError) do
        builder.send(:install_linux_qml, stage, "QT_INSTALL_QML" => qml)
      end

      assert_includes error.message, "required Qt QML module is missing"
      assert_includes error.message, "QtCharts"
    end
  end

  def test_client_audit_requires_the_chart_and_graph_qml_plugins
    audit = File.read(File.join(File.expand_path("..", __dir__), "scripts", "audit_client.rb"))

    assert_includes audit, '"QtCharts" => %w[libqtchartsqml2plugin.dylib qtchartsqml2plugin.dll libqtchartsqml2plugin.so]'
    assert_includes audit, '"QtGraphs" => %w[libgraphsplugin.dylib graphsplugin.dll libgraphsplugin.so]'
    assert_includes audit, "client archive cannot load #{'#{qml_module'}.tr('/', '.')}"
    # The forbidden payload list must not block what the framework now imports.
    refute_match(/QtCharts\|/, audit)
    refute_match(/\|QtGraphs/, audit)
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
