# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class QtBundleConfigurationTest < Minitest::Test
  def test_defaults_to_the_fusion_runtime_without_optional_features
    Dir.mktmpdir do |project|
      configuration = Zui::QtBundleConfiguration.load(project)

      assert_equal "Fusion", configuration.style
      assert_empty configuration.features
      assert_empty configuration.qml_modules
      assert_empty configuration.plugins
    end
  end

  def test_reads_deterministic_qt_runtime_overrides
    Dir.mktmpdir do |project|
      File.write(File.join(project, Zui::QtBundleConfiguration::CONFIG_FILE), JSON.generate(
        "components" => %w[video camera video],
        "qt" => {
          "style" => "Basic",
          "features" => %w[tls jpeg tls],
          "qml_modules" => %w[QtPositioning QtLocation],
          "plugins" => %w[position/libqtposition_positionpoll imageformats/libqjpeg]
        }
      ))

      configuration = Zui::QtBundleConfiguration.load(project)

      assert_equal %w[camera video], configuration.components
      assert_equal "Basic", configuration.style
      assert_equal %w[jpeg tls], configuration.features
      assert_equal %w[QtLocation QtPositioning], configuration.qml_modules
      assert_equal %w[imageformats/libqjpeg position/libqtposition_positionpoll], configuration.plugins
    end
  end

  def test_rejects_unsafe_plugin_paths
    Dir.mktmpdir do |project|
      File.write(File.join(project, Zui::QtBundleConfiguration::CONFIG_FILE),
                 '{"qt":{"plugins":["../outside"]}}')

      error = assert_raises(ArgumentError) { Zui::QtBundleConfiguration.load(project) }
      assert_includes error.message, "qt.plugins"
    end
  end
end
