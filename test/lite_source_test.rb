# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"
require_relative "../lib/zui"

class LiteSourceTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_inlines_framework_and_application_without_requires
    source = Zui::LiteSource.new(project: File.join(ROOT, "examples", "futuristic_dashboard")).call

    assert_includes source, "class Application"
    assert_includes source, "module FuturisticDashboard"
    assert_includes source, "FuturisticDashboard.run"
    refute_match(/^\s*require(?:_relative)?\b/, source)
  end

  def test_rejects_cruby_gems_with_a_full_mode_hint
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "main.rb"), "require 'paint'\n")

      error = assert_raises(ArgumentError) { Zui::LiteSource.new(project: directory).call }

      assert_includes error.message, "paint"
      assert_includes error.message, "--full"
    end
  end

  def test_full_mobile_source_preserves_external_gem_requires
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "main.rb"), "require 'paint'\nPaint.run\n")

      source = Zui::LiteSource.new(project: directory, allow_external_requires: true).call

      assert_includes source, "require 'paint'"
      assert_includes source, "Paint.run"
    end
  end

  def test_every_example_runs_on_the_zui_mruby
    mruby = ENV["ZUI_MRUBY"]
    skip "set ZUI_MRUBY to run the prebuilt lite-runtime smoke" unless mruby && File.executable?(mruby)

    Dir.mktmpdir do |directory|
      projects = Dir[File.join(ROOT, "examples", "*")].select do |project|
        File.file?(File.join(project, "main.rb"))
      end
      projects.each do |project|
        name = File.basename(project)
        program = File.join(directory, "#{name}.rb")
        File.write(program, Zui::LiteSource.new(project:).call)

        output, error, status = Open3.capture3(mruby, program, stdin_data: "")

        assert status.success?, "#{name}: #{error}"
        messages = output.each_line.map { |line| JSON.parse(line) }
        assert_equal "ready", messages.fetch(0).fetch("type"), name
        assert_equal "render", messages.fetch(1).fetch("type"), name
        assert messages.fetch(1).fetch("surfaces").key?("main"), name
      end
    end
  end
end
