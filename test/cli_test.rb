# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "stringio"
require "tmpdir"
require_relative "../lib/zui"
require_relative "../lib/zui/cli"

class CLITest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_new_generates_a_zui_only_ruby_application
    Dir.mktmpdir do |directory|
      output = StringIO.new
      Dir.chdir(directory) do
        assert_equal 0, Zui::CLI.run(["new", "Signal Board"], out: output, err: StringIO.new)
      end
      project = File.join(directory, "signal-board")
      main = File.read(File.join(project, "main.rb"))
      assert_includes main, 'require "zui"'
      assert_includes main, "Zui.app do"
      refute_match(/Omarchy|Quickshell/, main)
      assert_equal %w[README.md components main.rb], Dir.children(project).sort
    end
  end

  def test_validate_command_checks_the_render_protocol
    output = StringIO.new
    status = Zui::CLI.run(["validate", File.join(__dir__, "fixtures", "smoke_app.rb")], out: output, err: StringIO.new)

    assert_equal 0, status
    assert_includes output.string, "surfaces: main"
  end

  def test_version_executable_works_without_bundler
    stdout, stderr, status = Open3.capture3(File.join(ROOT, "bin", "zui"), "version")

    assert status.success?, stderr
    assert_equal "#{Zui::VERSION}\n", stdout
  end
end
