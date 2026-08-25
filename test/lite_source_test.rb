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

  def test_generated_source_runs_on_the_zui_mruby
    mruby = ENV["ZUI_MRUBY"]
    skip "set ZUI_MRUBY to run the prebuilt lite-runtime smoke" unless mruby && File.executable?(mruby)

    Dir.mktmpdir do |directory|
      program = File.join(directory, "app.rb")
      File.write(program, Zui::LiteSource.new(project: File.join(ROOT, "examples", "futuristic_dashboard")).call)

      output, error, status = Open3.capture3(mruby, program, stdin_data: "")

      assert status.success?, error
      messages = output.each_line.map { |line| JSON.parse(line) }
      assert_equal "ready", messages.fetch(0).fetch("type")
      assert_equal "render", messages.fetch(1).fetch("type")
      assert messages.fetch(1).fetch("surfaces").key?("main")
    end
  end
end
