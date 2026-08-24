# frozen_string_literal: true

require "minitest/autorun"
require "minitest/mock"
require "open3"
require "rbconfig"
require "stringio"
require "tmpdir"
require_relative "../lib/zui"
require_relative "../lib/zui/cli"

class CLITest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  FakeClient = Struct.new(:root, :configured, :configure_calls) do
    def configured? = configured

    def configure!
      self.configure_calls += 1
      self.configured = true
      root
    end
  end

  def test_new_generates_a_zui_only_ruby_application
    Dir.mktmpdir do |directory|
      output = StringIO.new
      Dir.chdir(directory) do
        assert_equal 0, Zui::CLI.run(["new", "Signal Board"], out: output, err: StringIO.new)
      end
      project = File.join(directory, "signal-board")
      main = File.read(File.join(project, "main.rb"))
      component = File.read(File.join(project, "components", "welcome.rb"))
      assert_includes main, 'require "zui"'
      assert_includes main, "module SignalBoard"
      assert_includes main, "Zui::Application.new(ui: WelcomeComponent)"
      assert_includes main, "SignalBoard.run"
      refute_match(/Omarchy|Quickshell/, main)
      refute_includes component, "Zui::Builder.include"
      assert_equal %w[README.md components main.rb], Dir.children(project).sort
    end
  end

  def test_version_executable_works_without_bundler
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, File.join(ROOT, "bin", "zui"), "version")

    assert status.success?, stderr
    assert_equal "#{Zui::VERSION}\n", stdout
  end

  def test_run_opens_the_requested_file_through_the_native_runner
    requested = nil
    runner = Object.new
    runner.define_singleton_method(:run) do |file|
      requested = file
      0
    end

    status = Zui::Runner.stub(:new, runner) do
      Zui::CLI.run(["run", File.join(__dir__, "fixtures", "smoke_app.rb")],
                   out: StringIO.new, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal File.join(__dir__, "fixtures", "smoke_app.rb"), requested
  end

  def test_configure_installs_the_client_and_enables_run_and_bundle
    client = FakeClient.new("/tmp/zui-client", false, 0)
    output = StringIO.new

    status = Zui::Client.stub(:new, client) do
      Zui::CLI.run(["configure"], out: output, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal 1, client.configure_calls
    assert_includes output.string, "Run: ready"
    assert_includes output.string, "Bundle: ready"
  end

  def test_doctor_is_read_only_and_points_to_fix
    client = FakeClient.new("/tmp/zui-client", false, 0)
    output = StringIO.new

    status = Zui::Client.stub(:new, client) do
      Zui::CLI.run(["doctor"], out: output, err: StringIO.new)
    end

    assert_equal 1, status
    assert_equal 0, client.configure_calls
    assert_includes output.string, "zui doctor --fix"
  end

  def test_doctor_fix_installs_the_client_and_enables_run_and_bundle
    client = FakeClient.new("/tmp/zui-client", false, 0)
    output = StringIO.new

    status = Zui::Client.stub(:new, client) do
      Zui::CLI.run(["doctor", "--fix"], out: output, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal 1, client.configure_calls
    assert_includes output.string, "GitHub Releases"
    assert_includes output.string, "Run: ready"
    assert_includes output.string, "Bundle: ready"
  end

  def test_doctor_fix_does_not_reinstall_a_ready_client
    client = FakeClient.new("/tmp/zui-client", true, 0)

    status = Zui::Client.stub(:new, client) do
      Zui::CLI.run(["doctor", "--fix"], out: StringIO.new, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal 0, client.configure_calls
  end

  def test_doctor_rejects_other_arguments
    error = StringIO.new
    assert_equal 1, Zui::CLI.run(["doctor", "--bundle"], out: StringIO.new, err: error)
    assert_includes error.string, "doctor accepts only --fix"
  end

  def test_removed_commands_are_not_public
    error = StringIO.new

    assert_equal 64, Zui::CLI.run(["validate"], out: StringIO.new, err: error)
    refute_includes error.string, "validate [DIRECTORY]"
    assert_equal 64, Zui::CLI.run(["launch"], out: StringIO.new, err: StringIO.new)
  end
end
