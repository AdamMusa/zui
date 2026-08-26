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
        assert_equal 0, Zui::CLI.run(["new", "signal_board"], out: output, err: StringIO.new)
      end
      project = File.join(directory, "signal-board")
      main = File.read(File.join(project, "main.rb"))
      component = File.read(File.join(project, "components", "welcome.rb"))
      config = File.read(File.join(project, "config.rb"))
      assets = File.join(project, "assets")
      assert_includes main, 'require "zui"'
      assert_includes main, "module SignalBoard"
      assert_includes main, 'title: "Signal Board"'
      assert_includes main, "Zui::Application.new(ui: WelcomeComponent)"
      assert_includes main, "SignalBoard.run"
      refute_match(/Omarchy|Quickshell/, main)
      refute_includes component, "Zui::Builder.include"
      assert_equal %w[Gemfile README.md assets components config.rb main.rb], Dir.children(project).sort
      gemfile = File.read(File.join(project, "Gemfile"))
      assert_includes gemfile, 'gem "zui"'
      assert_includes gemfile, "zui bundle --full"
      assert_includes config, "Zui::Dist.configure"
      assert_includes config, 'name "Signal Board"'
      assert_includes config, 'identifier "dev.zui.signal-board"'
      assert_includes config, 'description "A native Signal Board desktop application."'
      assert_includes config, 'publisher "Zui Project"'
      assert_includes config, 'license "MIT"'
      assert_includes config, 'homepage "https://github.com/AdamMusa/zui"'
      assert_includes config, 'linux: "assets/ruby.png"'
      assert_includes config, 'macos: "assets/ruby.icns"'
      assert_includes config, 'windows: "assets/ruby.ico"'
      assert_includes config, 'categories "Utility", "Development"'
      assert_equal %w[ruby.icns ruby.ico ruby.png], Dir.children(assets).sort
      Zui::Generator::RELEASE_ICONS.each do |name|
        assert_equal File.binread(File.join(Zui::Generator::DEFAULT_ASSETS, name)),
                     File.binread(File.join(assets, name))
      end
      refute File.exist?(File.join(assets, "ruby.jpg"))
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

  def test_bundle_can_explicitly_disable_tree_shaking
    options = nil
    distribution = Object.new
    distribution.define_singleton_method(:bundle) { |_source, **_arguments| "/tmp/Demo.app" }
    distribution.define_singleton_method(:tree_shake_report) { nil }

    status = Zui::Distribution.stub(:new, lambda { |**arguments|
      options = arguments
      distribution
    }) do
      Zui::CLI.run(["bundle", "--no-tree-shake", File.join(__dir__, "fixtures")],
                   out: StringIO.new, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal false, options.fetch(:tree_shake)
    assert_equal :lite, options.fetch(:runtime_mode)
  end

  def test_bundle_dist_uses_the_release_packager
    options = nil
    request = nil
    packager = Object.new
    packager.define_singleton_method(:package) do |source, **arguments|
      request = [source, arguments]
      ["/tmp/demo.deb", "/tmp/demo.rpm"]
    end
    packager.define_singleton_method(:tree_shake_report) { nil }
    output = StringIO.new

    status = Zui::DistPackager.stub(:new, lambda { |**arguments|
      options = arguments
      packager
    }) do
      Zui::CLI.run(["bundle", "--dist", "--output", "/tmp/releases", File.join(__dir__, "fixtures")],
                   out: output, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal true, options.fetch(:tree_shake)
    assert_equal :lite, options.fetch(:runtime_mode)
    assert_equal File.join(__dir__, "fixtures"), request.first
    assert_equal({ output: "/tmp/releases" }, request.last)
    assert_includes output.string, "/tmp/demo.deb"
    assert_includes output.string, "/tmp/demo.rpm"
  end

  def test_bundle_full_selects_the_private_cruby_runtime
    options = nil
    distribution = Object.new
    distribution.define_singleton_method(:bundle) { |_source, **_arguments| "/tmp/Demo.app" }
    distribution.define_singleton_method(:tree_shake_report) { nil }

    status = Zui::Distribution.stub(:new, lambda { |**arguments|
      options = arguments
      distribution
    }) do
      Zui::CLI.run(["bundle", "--full", File.join(__dir__, "fixtures")],
                   out: StringIO.new, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal :full, options.fetch(:runtime_mode)
  end

  def test_bundle_rejects_lite_and_full_together
    error = StringIO.new

    status = Zui::CLI.run(["bundle", "--lite", "--full", File.join(__dir__, "fixtures")],
                          out: StringIO.new, err: error)

    assert_equal 1, status
    assert_includes error.string, "only one of --lite or --full"
  end

  def test_configure_installs_the_client_and_enables_run_and_bundle
    client = FakeClient.new("/tmp/zui-client", false, 0)
    lite_runtime = FakeClient.new("/tmp/zui-lite", false, 0)
    output = StringIO.new

    status = with_runtimes(client, lite_runtime) do
      Zui::CLI.run(["configure"], out: output, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal 1, client.configure_calls
    assert_equal 1, lite_runtime.configure_calls
    assert_includes output.string, "Run: ready"
    assert_includes output.string, "Bundle --lite: ready"
  end

  def test_doctor_is_read_only_and_points_to_fix
    client = FakeClient.new("/tmp/zui-client", false, 0)
    lite_runtime = FakeClient.new("/tmp/zui-lite", false, 0)
    output = StringIO.new

    status = with_runtimes(client, lite_runtime) do
      Zui::CLI.run(["doctor"], out: output, err: StringIO.new)
    end

    assert_equal 1, status
    assert_equal 0, client.configure_calls
    assert_equal 0, lite_runtime.configure_calls
    assert_includes output.string, "zui doctor --fix"
  end

  def test_doctor_fix_installs_the_client_and_enables_run_and_bundle
    client = FakeClient.new("/tmp/zui-client", false, 0)
    lite_runtime = FakeClient.new("/tmp/zui-lite", false, 0)
    output = StringIO.new

    status = with_runtimes(client, lite_runtime) do
      Zui::CLI.run(["doctor", "--fix"], out: output, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal 1, client.configure_calls
    assert_equal 1, lite_runtime.configure_calls
    assert_includes output.string, "GitHub Releases"
    assert_includes output.string, "Run: ready"
    assert_includes output.string, "Bundle --lite: ready"
  end

  def test_doctor_fix_does_not_reinstall_a_ready_client
    client = FakeClient.new("/tmp/zui-client", true, 0)
    lite_runtime = FakeClient.new("/tmp/zui-lite", true, 0)

    status = with_runtimes(client, lite_runtime) do
      Zui::CLI.run(["doctor", "--fix"], out: StringIO.new, err: StringIO.new)
    end

    assert_equal 0, status
    assert_equal 0, client.configure_calls
    assert_equal 0, lite_runtime.configure_calls
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

  private

  def with_runtimes(client, lite_runtime, &block)
    Zui::LiteRuntime.stub(:new, lite_runtime) do
      Zui::Client.stub(:new, client, &block)
    end
  end
end
