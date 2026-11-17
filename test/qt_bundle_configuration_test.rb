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
      assert_empty configuration.ruby_stdlib
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
        },
        "ruby" => { "stdlib" => %w[openssl net/http openssl] }
      ))

      configuration = Zui::QtBundleConfiguration.load(project)

      assert_equal %w[camera video], configuration.components
      assert_equal "Basic", configuration.style
      assert_equal %w[jpeg tls], configuration.features
      assert_equal %w[QtLocation QtPositioning], configuration.qml_modules
      assert_equal %w[imageformats/libqjpeg position/libqtposition_positionpoll], configuration.plugins
      assert_equal %w[net/http openssl], configuration.ruby_stdlib
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

  def test_rejects_unknown_feature_names_instead_of_silently_bloating_the_runtime
    Dir.mktmpdir do |project|
      File.write(File.join(project, Zui::QtBundleConfiguration::CONFIG_FILE),
                 '{"qt":{"features":["everything"]}}')

      error = assert_raises(ArgumentError) { Zui::QtBundleConfiguration.load(project) }
      assert_includes error.message, "unknown Qt features"
    end
  end

  def test_rejects_unsafe_ruby_standard_library_paths
    Dir.mktmpdir do |project|
      File.write(File.join(project, Zui::QtBundleConfiguration::CONFIG_FILE),
                 '{"ruby":{"stdlib":["../outside"]}}')

      error = assert_raises(ArgumentError) { Zui::QtBundleConfiguration.load(project) }
      assert_includes error.message, "ruby.stdlib"
    end
  end
end
