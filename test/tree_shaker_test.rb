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
      "QtMultimedia" => "module QtMultimedia\ndepends QtQuick auto\n",
      "QtQuick3D" => "module QtQuick3D\ndepends QtQuick auto\n",
      "Qt/labs/qmlmodels" => "module Qt.labs.qmlmodels\ndepends QtQml.Models auto\n"
    }.each do |relative, qmldir|
      directory = File.join(native, "qml", relative)
      FileUtils.mkdir_p(directory)
      File.write(File.join(directory, "qmldir"), qmldir)
    end
    %w[multimedia assetimporters imageformats iconengines networkinformation tls].each do |name|
      directory = File.join(native, "plugins", name)
      FileUtils.mkdir_p(directory)
      File.write(File.join(directory, ".fixture"), name)
    end
  end
end
