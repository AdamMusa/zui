# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/client_fixture"

class TreeShakerTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_keeps_components_in_conditional_branches_and_prunes_unreferenced_features
    with_payload(<<~RUBY) do |project, framework, native, platform|
      require "zui"
      Zui.app do
        app do
          text "status"
          video "movie.mp4" if ENV["ENABLE_VIDEO"] == "1"
        end
      end
    RUBY
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.components, :container
      assert_includes report.components, :text
      assert_includes report.components, :video
      assert File.file?(File.join(framework, "Components", "Builtins", "Video.qml"))
      refute File.exist?(File.join(framework, "Components", "Builtins", "Camera.qml"))
      assert File.directory?(File.join(native, "qml", "QtMultimedia"))
      refute File.exist?(File.join(native, "qml", "QtQuick3D"))
      assert File.directory?(File.join(native, "plugins", "multimedia"))
      refute File.exist?(File.join(native, "plugins", "assetimporters"))
      refute File.exist?(File.join(native, "plugins", "sqldrivers"))
      refute File.exist?(File.join(native, "plugins", "styles"))
    end
  end

  def test_explicit_component_manifest_supports_computed_component_types
    with_payload("kind = ARGV.first\nZui.app { app { component(kind) } }\n") do |project, framework, native, platform|
      File.write(File.join(project, Zui::TreeShaker::CONFIG_FILE), JSON.generate(
        "components" => %w[camera]
      ))

      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.components, :camera
      assert File.file?(File.join(framework, "Components", "Builtins", "Camera.qml"))
      assert File.directory?(File.join(native, "qml", "QtMultimedia"))
    end
  end

  def test_configured_controls_style_and_qml_modules_define_the_native_module_closure
    with_payload("Zui.app { app { text 'hello' } }\n") do |project, framework, native, platform|
      File.write(File.join(project, Zui::TreeShaker::CONFIG_FILE), JSON.generate(
        "qt" => { "style" => "Basic", "qml_modules" => ["QtPositioning"] }
      ))

      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_equal "Basic", report.qt_style
      assert_includes report.qml_modules, "QtQuick.Controls.Basic"
      assert_includes report.qml_modules, "QtPositioning"
      refute_includes report.qml_modules, "QtQuick.Controls.Fusion"
      refute File.exist?(File.join(native, "qml", "QtQuick", "Controls", "Fusion"))
    end
  end

  def test_derives_image_and_tls_plugins_from_project_source_literals
    with_payload(<<~RUBY) do |project, framework, native, platform|
      Zui.app do
        app do
          image "assets/photo.jpg"
          image "assets/diagram.svg"
          image "https://example.test/avatar.png"
        end
      end
    RUBY
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!
      plugins = File.join(native, "plugins")

      assert_equal %w[jpeg svg tls], report.qt_features
      assert File.file?(File.join(plugins, "imageformats", "libqjpeg.so"))
      assert File.file?(File.join(plugins, "imageformats", "libqsvg.so"))
      refute File.exist?(File.join(plugins, "imageformats", "libqgif.so"))
      assert File.file?(File.join(plugins, "tls", "libqopensslbackend.so"))
      refute File.exist?(File.join(plugins, "tls", "libqcertonlybackend.so"))
      refute File.exist?(File.join(plugins, "networkinformation"))
      refute File.exist?(File.join(plugins, "iconengines"))
    end
  end

  def test_explicit_plugin_features_cover_runtime_computed_sources
    with_payload("Zui.app { app { image ENV.fetch('IMAGE_SOURCE') } }\n") do |project, framework, native, platform|
      File.write(File.join(project, Zui::TreeShaker::CONFIG_FILE), JSON.generate(
        "qt" => {
          "features" => %w[gif network-reachability svg-icons],
          "plugins" => ["imageformats/qico"]
        }
      ))

      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!
      plugins = File.join(native, "plugins")

      assert_equal %w[gif network-reachability svg-icons], report.qt_features
      assert File.file?(File.join(plugins, "imageformats", "libqgif.so"))
      assert File.file?(File.join(plugins, "imageformats", "libqico.so"))
      assert File.file?(File.join(plugins, "iconengines", "libqsvgicon.so"))
      assert File.file?(File.join(plugins, "networkinformation", "libqnetworklistmanager.so"))
      refute File.exist?(File.join(plugins, "tls"))
    end
  end

  def test_png_only_images_need_no_optional_qt_codec_plugin
    with_payload("Zui.app { app { image 'assets/local.png' } }\n") do |project, framework, native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_empty report.qt_features
      refute File.exist?(File.join(native, "plugins", "imageformats"))
      refute File.exist?(File.join(native, "plugins", "tls"))
    end
  end

  def test_detects_keyword_dynamic_components
    with_payload("Zui.app { app { dynamic type: :grid, id: :results } }\n") do |project, framework, native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.components, :grid
      assert File.file?(File.join(framework, "Components", "Builtins", "Grid.qml"))
    end
  end

  def test_keeps_qml_modules_imported_by_runtime_created_objects
    with_payload("Zui.app { app { table_view rows: [[1]] } }\n") do |project, framework, native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.qml_modules, "Qt.labs.qmlmodels"
      assert File.directory?(File.join(native, "qml", "Qt", "labs", "qmlmodels"))
    end
  end

  def test_prunes_unreferenced_support_helpers_and_their_qml_modules
    with_payload("Zui.app { app { stacked_bar_chart [] } }\n") do |project, framework, native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!
      support = File.join(framework, "Components", "Builtins", "Support")

      assert File.file?(File.join(support, "ChartCanvas.qml"))
      refute File.exist?(File.join(support, "ModelView3dScene.qml"))
      refute File.exist?(File.join(support, "OptionalModuleState.js"))
      refute_includes report.qml_modules, "QtQuick3D"
      refute File.exist?(File.join(native, "qml", "QtQuick3D"))
    end
  end

  def test_keeps_support_files_loaded_by_relative_url
    with_payload("Zui.app { app { model_view_3d source: 'model.glb' } }\n") do |project, framework, native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!
      support = File.join(framework, "Components", "Builtins", "Support")

      assert File.file?(File.join(support, "ModelView3dScene.qml"))
      assert File.file?(File.join(support, "OptionalModuleState.js"))
      assert_includes report.qml_modules, "QtQuick3D"
      assert File.directory?(File.join(native, "qml", "QtQuick3D"))
    end
  end

  def test_keeps_only_sqlite_driver_for_qml_local_storage
    with_payload("Zui.app { app { text 'stored' } }\n") do |project, framework, native, platform|
      text_adapter = File.join(framework, "Components", "Builtins", "Text.qml")
      File.write(text_adapter, "import QtQuick.LocalStorage\n#{File.read(text_adapter)}")
      drivers = File.join(native, "plugins", "sqldrivers")
      File.write(File.join(drivers, "libqsqlite.so"), "sqlite")
      File.write(File.join(drivers, "libqmysql.so"), "mysql")

      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.qml_modules, "QtQuick.LocalStorage"
      assert File.file?(File.join(drivers, "libqsqlite.so"))
      refute File.exist?(File.join(drivers, "libqmysql.so"))
      refute File.exist?(File.join(drivers, ".fixture"))
    end
  end

  def test_keeps_linux_desktop_platform_plugins
    with_payload("Zui.app { app { text 'hello' } }\n") do |project, framework, native, platform|
      platforms = File.join(native, "plugins", "platforms")
      FileUtils.mkdir_p(platforms)
      %w[libqxcb.so libqwayland-egl.so libqwayland-generic.so libqoffscreen.so libqminimal.so].each do |name|
        File.write(File.join(platforms, name), name)
      end

      Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      %w[libqxcb.so libqwayland-egl.so libqwayland-generic.so libqoffscreen.so].each do |name|
        assert File.file?(File.join(platforms, name)), "expected #{name} to survive tree shaking"
      end
      refute File.exist?(File.join(platforms, "libqminimal.so"))
    end
  end

  def test_expands_dependencies_between_builtin_adapters
    with_payload("Zui.app { app { data_table [] } }\n") do |project, framework, native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.components, :data_table
      assert_includes report.components, :table_view
      assert File.file?(File.join(framework, "Components", "Builtins", "TableView.qml"))
    end
  end

  def test_rejects_invalid_explicit_component_configuration
    with_payload("Zui.app { app { text 'hello' } }\n") do |project, framework, native, platform|
      File.write(File.join(project, Zui::TreeShaker::CONFIG_FILE), '{"components":["browser"]}')

      error = assert_raises(ArgumentError) do
        Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!
      end
      assert_includes error.message, "unknown component"
    end
  end

  def test_ignores_the_distribution_dsl_when_selecting_components
    with_payload("Zui.app { app { text 'hello' } }\n") do |project, framework, native, platform|
      File.write(File.join(project, "config.rb"), "Zui::Dist.configure { icon linux: 'assets/icon.png' }\n")

      report = Zui::TreeShaker.new(project:, framework:, native:, platform:).shake!

      assert_includes report.components, :text
      refute_includes report.components, :icon
    end
  end

  def test_tree_shakes_a_mobile_framework_without_a_desktop_native_client
    with_payload("Zui.app { app { text 'mobile' } }\n") do |project, framework, _native, platform|
      report = Zui::TreeShaker.new(project:, framework:, native: nil, platform:).shake!

      assert_includes report.components, :text
      assert File.file?(File.join(framework, "Components", "Builtins", "Text.qml"))
      refute File.exist?(File.join(framework, "Components", "Builtins", "Camera.qml"))
      assert_empty report.qt_plugins
      assert_operator report.saved_bytes, :>, 0
    end
  end

  def test_mobile_qml_modules_are_retained_only_when_the_app_uses_them
    with_payload(<<~RUBY) do |project, framework, _native, _platform|
      Zui.app do
        app do
          safe_area do
            map provider: "osm"
            accelerometer active: true
            text_to_speech
            web_view "about:blank", visible: false
          end
        end
      end
    RUBY
      platform = Zui::Platform.new(os: :ios, arch: :arm64)
      report = Zui::TreeShaker.new(project:, framework:, native: nil, platform:).shake!

      %i[accelerometer map safe_area text_to_speech web_view].each do |component|
        assert_includes report.components, component
      end
      %w[QtLocation QtPositioning QtSensors QtTextToSpeech QtWebView].each do |qml_module|
        assert_includes report.qml_modules, qml_module
      end
      refute_includes report.qml_modules, "QtQuick.Pdf"
      assert File.file?(File.join(framework, "Components", "Builtins", "WebView.qml"))
      refute File.exist?(File.join(framework, "Components", "Builtins", "PdfView.qml"))
      assert_operator report.saved_bytes, :>, 0
    end
  end

  private

  def with_payload(source)
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      framework = File.join(directory, "runtime", "qml")
      native = File.join(directory, "runtime", "native")
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "main.rb"), source)
      Zui::Runtime.install_qml(framework, framework_root: ROOT)
      ClientFixture.create(native, platform:)
      install_native_modules(native)
      yield project, framework, native, platform
    end
  end

  def install_native_modules(native)
    {
      "QtQuick" => "module QtQuick\n",
      "QtQuick/LocalStorage" => "module QtQuick.LocalStorage\ndepends QtQuick auto\n",
      "QtMultimedia" => "module QtMultimedia\ndepends QtQuick auto\n",
      "QtQuick3D" => "module QtQuick3D\ndepends QtQuick auto\n",
      "QtQuick/Controls/Basic" => "module QtQuick.Controls.Basic\ndepends QtQuick auto\n",
      "QtQuick/Controls/Fusion" => "module QtQuick.Controls.Fusion\nimport QtQuick.Controls.Basic auto\n",
      "QtPositioning" => "module QtPositioning\ndepends QtCore auto\n",
      "Qt/labs/qmlmodels" => "module Qt.labs.qmlmodels\ndepends QtQml.Models auto\n"
    }.each do |relative, qmldir|
      directory = File.join(native, "qml", relative)
      FileUtils.mkdir_p(directory)
      File.write(File.join(directory, "qmldir"), qmldir)
    end
    %w[multimedia assetimporters imageformats iconengines networkinformation sqldrivers styles tls].each do |name|
      directory = File.join(native, "plugins", name)
      FileUtils.mkdir_p(directory)
      File.write(File.join(directory, ".fixture"), name)
    end
    {
      "imageformats" => %w[libqgif.so libqico.so libqjpeg.so libqsvg.so libqwebp.so],
      "iconengines" => %w[libqsvgicon.so],
      "networkinformation" => %w[libqnetworklistmanager.so],
      "tls" => %w[libqcertonlybackend.so libqopensslbackend.so],
      "sqldrivers" => %w[libqmysql.so libqsqlite.so]
    }.each do |directory, plugins|
      plugins.each { |plugin| File.write(File.join(native, "plugins", directory, plugin), plugin) }
    end
  end
end
