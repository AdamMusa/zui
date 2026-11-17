# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class RubyRuntimeShakerTest < Minitest::Test
  def test_keeps_literal_standard_library_closure_and_all_encodings
    with_runtime do |project, runtime, load_paths|
      write_project(project, 'require "zui"')
      write_gem(runtime, "zui", 'require "json"')

      report = shaker(project, runtime, load_paths).shake!

      assert report.tree_shaken?
      assert_operator report.saved_bytes, :>, 0
      assert_includes report.features, "json"
      assert File.file?(File.join(load_paths.first, "json.rb"))
      assert File.file?(File.join(load_paths.last, "json", "ext", "parser.so"))
      assert File.file?(File.join(load_paths.last, "enc", "legacy.so"))
      refute File.exist?(File.join(load_paths.first, "openssl.rb"))
      refute File.exist?(File.join(load_paths.last, "openssl.so"))
      refute File.exist?(File.join(load_paths.first, "unused.rb"))
    end
  end

  def test_keeps_explicitly_configured_standard_library_features
    with_runtime do |project, runtime, load_paths|
      write_project(project, 'require "zui"')
      write_gem(runtime, "zui", 'require "json"')

      report = shaker(project, runtime, load_paths, configured_features: ["openssl"]).shake!

      assert report.tree_shaken?
      assert_includes report.features, "openssl"
      assert File.file?(File.join(load_paths.first, "openssl.rb"))
      assert File.file?(File.join(load_paths.last, "openssl.so"))
    end
  end

  def test_analyzes_additional_generated_application_sources
    with_runtime do |project, runtime, load_paths|
      write_project(project, "module Application; end")
      generated = File.join(File.dirname(project), "generated-app.rb")
      File.write(generated, "require 'json'\n")

      report = Zui::RubyRuntimeShaker.new(
        project:, runtime:, load_paths:, additional_sources: [generated]
      ).shake!

      assert report.tree_shaken?
      assert_includes report.features, "json"
      assert File.file?(File.join(load_paths.first, "json.rb"))
      refute File.exist?(File.join(load_paths.first, "unused.rb"))
    end
  end

  def test_falls_back_for_dynamic_requires
    with_runtime do |project, runtime, load_paths|
      write_project(project, "feature = 'json'\nrequire feature")

      report = shaker(project, runtime, load_paths).shake!

      refute report.tree_shaken?
      assert_includes report.fallback, "dynamic require"
      assert_includes report.fallback, ":2"
      assert File.file?(File.join(load_paths.first, "unused.rb"))
    end
  end

  def test_falls_back_when_the_application_uses_rubygems_apis
    with_runtime do |project, runtime, load_paths|
      write_project(project, "Gem::Version.new('1.0.0')")

      report = shaker(project, runtime, load_paths).shake!

      refute report.tree_shaken?
      assert_includes report.fallback, "RubyGems runtime APIs"
      assert File.file?(File.join(load_paths.first, "unused.rb"))
    end
  end

  def test_falls_back_for_computed_autoloads
    with_runtime do |project, runtime, load_paths|
      write_project(project, "feature = 'json'\nautoload :JSON, feature")

      report = shaker(project, runtime, load_paths).shake!

      refute report.tree_shaken?
      assert_includes report.fallback, "dynamic require"
      assert File.file?(File.join(load_paths.first, "unused.rb"))
    end
  end

  def test_rejects_unavailable_configured_features
    with_runtime do |project, runtime, load_paths|
      write_project(project, 'require "zui"')

      error = assert_raises(ArgumentError) do
        shaker(project, runtime, load_paths, configured_features: ["missing/service"]).shake!
      end

      assert_includes error.message, "configured Ruby standard library feature is unavailable"
    end
  end

  private

  def with_runtime
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      runtime = File.join(directory, "runtime")
      common = File.join(runtime, "lib", "ruby", "4.0.0")
      architecture = File.join(common, "fixture-platform")
      FileUtils.mkdir_p([
        project,
        File.join(common, "json"),
        File.join(architecture, "json", "ext"),
        File.join(architecture, "enc", "trans")
      ])
      File.write(File.join(common, "json.rb"), "require 'json/ext'\n")
      File.write(File.join(common, "json", "ext.rb"), "require 'json/ext/parser'\n")
      File.write(File.join(common, "openssl.rb"), "require 'openssl.so'\n")
      File.write(File.join(common, "unused.rb"), "module Unused; end\n")
      File.binwrite(File.join(architecture, "json", "ext", "parser.so"), "json-native")
      File.binwrite(File.join(architecture, "openssl.so"), "openssl-native")
      File.binwrite(File.join(architecture, "enc", "encdb.so"), "encoding-database")
      File.binwrite(File.join(architecture, "enc", "trans", "transdb.so"), "transcoder-database")
      File.binwrite(File.join(architecture, "enc", "legacy.so"), "legacy-encoding")
      yield project, runtime, [common, architecture]
    end
  end

  def write_project(project, source)
    File.write(File.join(project, "main.rb"), "#{source}\n")
  end

  def write_gem(runtime, name, source)
    path = File.join(runtime, "gems", "gems", "#{name}-1.0.0", "lib", name)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, "runtime.rb"), "#{source}\n")
  end

  def shaker(project, runtime, load_paths, configured_features: [])
    Zui::RubyRuntimeShaker.new(project:, runtime:, load_paths:, configured_features:)
  end
end
