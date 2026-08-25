# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "rbconfig"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/client_fixture"

class DistributionTest < Minitest::Test
  FakeRuntimeBuilder = Struct.new(:platform, :engine) do
    def initialize(platform, engine = "mruby") = super

    def install(project:, destination:)
      name = engine == "mruby" ? "mruby" : "ruby"
      name = "#{name}.exe" if platform.windows?
      executable = "bin/#{name}"
      FileUtils.mkdir_p(File.join(destination, "bin"))
      File.write(File.join(destination, executable), "runtime-fixture")
      FileUtils.chmod(0o755, File.join(destination, executable)) unless platform.windows?
      if engine == "mruby"
        File.write(File.join(destination, "app.rb"), Zui::LiteSource.new(project:).call)
      end
      Zui::ApplicationRuntime.new(
        engine:, version: engine == "mruby" ? "4.0.0" : "3.3.0", executable:,
        program: engine == "mruby" ? "app.rb" : nil,
        load_path: engine == "mruby" ? "" : nil,
        environment: engine == "cruby" ? {
          "RUBYLIB" => ["lib/ruby/3.3.0"],
          "GEM_HOME" => ["gems"],
          "GEM_PATH" => ["gems"]
        } : {}
      ).write(destination)
    end
  end

  def test_linux_bundle_contains_app_framework_and_native_runtimes
    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    with_project(platform) do |project, client|
      destination = lite_distribution(client:, platform:).bundle(project)

      assert_posix_executable File.join(destination, "run")
      assert_posix_executable File.join(destination, "runtime", "native", "bin", "zui-host")
      assert File.file?(File.join(destination, "runtime", "native", "client.json"))
      assert File.file?(File.join(destination, "runtime", "native", "lib", ".fixture"))
      assert File.file?(File.join(destination, "app", "main.rb"))
      assert File.file?(File.join(destination, "runtime", "lib", "zui.rb"))
      refute File.exist?(File.join(destination, "runtime", "lib", "zui", "client_builder.rb"))
      refute File.exist?(File.join(destination, "runtime", "lib", "zui", "client_packager.rb"))
      assert File.file?(File.join(destination, "runtime", "qml", "Desktop.qml"))
      manifest = JSON.parse(File.read(File.join(destination, "zui-bundle.json")))
      assert_equal "linux", manifest.fetch("platform")
      assert_equal Zui::VERSION, manifest.fetch("client_version")
      assert_equal true, manifest.fetch("tree_shaken")
      assert_equal "lite", manifest.fetch("ruby_runtime")
      assert_includes manifest.fetch("tree_shake").fetch("components"), "text"
      refute File.exist?(File.join(destination, "runtime", "qml", "Components", "Builtins", "Camera.qml"))
      assert_equal 1, Dir[File.join(destination, "share", "applications", "*.desktop")].length
      launcher = File.read(File.join(destination, "run"))
      assert_includes launcher, 'ruby_command="$ruby_root/bin/mruby"'
      assert_includes launcher, '--program "$bundle_dir/runtime/ruby/app.rb"'
      assert_includes launcher, '--load-path ""'
      refute_includes launcher, "command -v ruby"
      assert_includes launcher, '$native_dir/lib'
    end
  end

  def test_macos_bundle_has_a_standard_application_layout
    platform = Zui::Platform.new(os: :macos, arch: :arm64)
    with_project(platform) do |project, client|
      destination = File.join(project, "package", "Demo.app")
      lite_distribution(client:, platform:).bundle(project, destination:)

      contents = File.join(destination, "Contents")
      assert_posix_executable File.join(contents, "MacOS", "run")
      assert_posix_executable File.join(contents, "Resources", "runtime", "native", "bin", "zui-host")
      assert File.file?(File.join(contents, "Info.plist"))
      assert File.file?(File.join(contents, "Resources", "app", "main.rb"))
      assert File.file?(File.join(contents, "Resources", "runtime", "qml", "Desktop.qml"))
      assert_includes File.read(File.join(contents, "Info.plist")), "CFBundlePackageType"
      launcher = File.read(File.join(contents, "MacOS", "run"))
      assert_includes launcher, 'ruby_command="$ruby_root/bin/mruby"'
      assert_includes launcher, '--program "$resources/runtime/ruby/app.rb"'
    end
  end

  def test_windows_bundle_has_native_runtime_and_safe_launchers
    platform = Zui::Platform.new(os: :windows, arch: :x86_64)
    with_project(platform) do |project, client|
      destination = lite_distribution(client:, platform:).bundle(project)

      assert File.file?(File.join(destination, "run.cmd"))
      refute File.exist?(File.join(destination, "run.rb"))
      assert File.file?(File.join(destination, "runtime", "native", "bin", "zui-host.exe"))
      assert File.file?(File.join(destination, "app", "main.rb"))
      assert File.file?(File.join(destination, "runtime", "lib", "zui.rb"))
      assert File.file?(File.join(destination, "runtime", "qml", "Desktop.qml"))
      assert_equal "windows", JSON.parse(File.read(File.join(destination, "zui-bundle.json"))).fetch("platform")
      launcher = File.read(File.join(destination, "run.cmd"))
      assert_includes launcher, "%ruby_root%\\bin\\mruby.exe"
      assert_includes launcher, "%ruby_root%\\app.rb"
      refute_includes launcher, "Omarchy"
    end
  end

  def test_existing_bundle_destination_is_never_removed
    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    with_project(platform) do |project, client|
      destination = File.join(project, "my-existing-output")
      FileUtils.mkdir_p(destination)
      File.write(File.join(destination, "personal.txt"), "keep")

      assert_raises(ArgumentError) do
        lite_distribution(client:, platform:).bundle(project, destination:)
      end
      assert_equal "keep", File.read(File.join(destination, "personal.txt"))
    end
  end

  def test_full_linux_bundle_uses_only_its_private_cruby
    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    with_project(platform) do |project, client|
      destination = Zui::Distribution.new(
        client:, platform:, runtime_mode: :full, runtime_builder: FakeRuntimeBuilder.new(platform, "cruby")
      ).bundle(project)

      launcher = File.read(File.join(destination, "run"))
      assert_includes launcher, 'ruby_root="$bundle_dir/runtime/ruby"'
      assert_includes launcher, 'ruby_command="$ruby_root/bin/ruby"'
      assert_includes launcher, 'export GEM_HOME="${ruby_root}/gems"'
      refute_includes launcher, "command -v ruby"
      assert File.file?(File.join(destination, "runtime", "ruby", "runtime.json"))
      manifest = JSON.parse(File.read(File.join(destination, "zui-bundle.json")))
      assert_equal "full", manifest.fetch("ruby_runtime")
    end
  end

  def test_full_windows_bundle_starts_the_host_without_system_ruby
    platform = Zui::Platform.new(os: :windows, arch: :x86_64)
    with_project(platform) do |project, client|
      destination = Zui::Distribution.new(
        client:, platform:, runtime_mode: :full, runtime_builder: FakeRuntimeBuilder.new(platform, "cruby")
      ).bundle(project)

      launcher = File.read(File.join(destination, "run.cmd"))
      assert_includes launcher, "%ruby_root%\\bin\\ruby.exe"
      assert_includes launcher, "runtime\\native\\bin\\zui-host.exe"
      assert_includes launcher, "--ruby"
      refute File.exist?(File.join(destination, "run.rb"))
      refute_match(/^ruby /, launcher)
    end
  end

  def test_tree_shaking_can_be_disabled_for_metaprogrammed_projects
    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    with_project(platform) do |project, client|
      destination = File.join(project, "unshaken")
      distribution = lite_distribution(client:, platform:, tree_shake: false)
      distribution.bundle(project, destination:)

      assert_nil distribution.tree_shake_report
      manifest = JSON.parse(File.read(File.join(destination, "zui-bundle.json")))
      assert_equal false, manifest.fetch("tree_shaken")
      assert File.file?(File.join(destination, "runtime", "qml", "Components", "Builtins", "Camera.qml"))
    end
  end

  def test_linux_launcher_uses_the_ruby_that_built_the_bundle_with_a_gui_path
    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    with_project(platform) do |project, client|
      File.write(client.executable, <<~SH)
        #!/bin/sh
        printf '%s\n' "$@" > "$ZUI_ARGUMENT_LOG"
      SH
      FileUtils.chmod(0o755, client.executable)
      destination = lite_distribution(client:, platform:, ruby: RbConfig.ruby).bundle(project)
      argument_log = File.join(project, "native-arguments.log")

      if Gem.win_platform?
        launcher = File.read(File.join(destination, "run"))
        assert_includes launcher, 'ruby_command="$ruby_root/bin/mruby"'
        next
      end

      launched = system(
        { "PATH" => "/usr/bin:/bin", "ZUI_RUBY" => nil, "ZUI_ARGUMENT_LOG" => argument_log },
        File.join(destination, "run"), out: File::NULL, err: File::NULL
      )

      assert launched
      arguments = File.readlines(argument_log, chomp: true)
      assert_equal File.join(destination, "runtime", "ruby", "bin", "mruby"),
                   arguments.fetch(arguments.index("--ruby") + 1)
    end
  end

  def test_bundle_requires_configuration_instead_of_using_system_qt
    Dir.mktmpdir do |directory|
      project = File.join(directory, "demo")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "main.rb"), "require 'zui'\n")
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      client = Zui::Client.new(platform:, cache_root: File.join(directory, "cache"),
                               environment: { "HOME" => directory })

      error = assert_raises(ArgumentError) do
        Zui::Distribution.new(client:, platform:).bundle(project)
      end
      assert_includes error.message, "zui doctor --fix"
    end
  end

  private

  def assert_posix_executable(path)
    assert File.file?(path)
    assert File.executable?(path) unless Gem.win_platform?
  end

  def lite_distribution(client:, platform:, **options)
    Zui::Distribution.new(
      client:, platform:, runtime_builder: FakeRuntimeBuilder.new(platform), **options
    )
  end

  def with_project(platform)
    Dir.mktmpdir do |directory|
      project = File.join(directory, "demo")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "main.rb"), File.read(File.join(__dir__, "fixtures", "smoke_app.rb")))
      File.write(File.join(project, "asset.txt"), "owned by app")
      client_root = ClientFixture.create(File.join(directory, "client"), platform:)
      client = Zui::Client.new(platform:, environment: { "ZUI_CLIENT_ROOT" => client_root })
      yield project, client
    end
  end
end
