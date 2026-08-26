# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class MobileTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  SuccessfulStatus = Struct.new(:exitstatus) do
    def success? = true
  end

  class RuntimeBuildCommand
    attr_reader :calls

    def initialize(mruby_root, build_name)
      @mruby_root = mruby_root
      @build_name = build_name
      @calls = []
    end

    def run(arguments, **options)
      @calls << [arguments, options]
      library = File.join(@mruby_root, "build", @build_name, "lib")
      compiler = File.join(@mruby_root, "build", "host", "bin")
      FileUtils.mkdir_p(library)
      FileUtils.mkdir_p(compiler)
      File.write(File.join(library, "libmruby.a"), "runtime")
      File.write(File.join(compiler, "mrbc"), "compiler")
      FileUtils.chmod(0o755, File.join(compiler, "mrbc"))
      Zui::CommandResult.new(stdout: "", stderr: "", status: SuccessfulStatus.new(0))
    end
  end

  def test_ios_stage_contains_lite_application_assets_and_app_icon_catalog
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      create_project(project)
      output = File.join(directory, "build")
      builder = Zui::Mobile::IOSBuilder.new(
        project:, output:, framework_root: ROOT,
        qt_ios: dependencies.fetch(:qt_ios), qt_host: dependencies.fetch(:qt_host),
        mruby_root: dependencies.fetch(:mruby), mruby_json: dependencies.fetch(:mruby_json),
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )

      builder.send(:validate!)
      config = Zui::Dist.load(project:, platform: Zui::Mobile::IOSBuilder::IOS_PLATFORM)
      stage = builder.send(:prepare_stage, config)

      application = File.read(File.join(stage, "app.rb"))
      manifest = JSON.parse(File.read(File.join(stage, "Assets.xcassets", "AppIcon.appiconset", "Contents.json")))
      assert_includes application, "class EmbeddedOutput"
      assert_includes application, 'text "Touch ready"'
      assert_equal File.binread(File.join(project, "assets", "ruby.png")),
                   File.binread(File.join(stage, "assets", "ruby.png"))
      assert_equal "AppIcon.png", manifest.dig("images", 0, "filename")
      assert File.file?(File.join(stage, "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png"))
    end
  end

  def test_ios_builder_rejects_non_macos_hosts
    builder = Zui::Mobile::IOSBuilder.new(
      project: ".", host_platform: Zui::Platform.new(os: :linux, arch: :x86_64)
    )

    error = assert_raises(ArgumentError) { builder.send(:validate!) }

    assert_includes error.message, "must be built on macOS"
  end

  def test_clean_mruby_build_passes_the_configuration_through_the_environment
    Dir.mktmpdir do |directory|
      dependencies = create_dependencies(directory)
      build_name = "zui-ios-simulator-x86_64-bytecode"
      command = RuntimeBuildCommand.new(dependencies.fetch(:mruby), build_name)
      builder = Zui::Mobile::IOSBuilder.new(
        project: directory, framework_root: ROOT, command:,
        qt_ios: dependencies.fetch(:qt_ios), qt_host: dependencies.fetch(:qt_host),
        mruby_root: dependencies.fetch(:mruby), mruby_json: dependencies.fetch(:mruby_json),
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )

      builder.send(:build_mruby, "/Simulator.sdk", build_name)

      arguments, options = command.calls.fetch(0)
      assert_equal [RbConfig.ruby, "minirake"], arguments
      assert_equal File.join(ROOT, "runtime", "mruby", "ios_simulator_build_config.rb"),
                   options.dig(:env, "MRUBY_CONFIG")
      assert_equal "x86_64", options.dig(:env, "ZUI_IOS_SIMULATOR_ARCH")
      assert_equal "/Simulator.sdk", options.dig(:env, "ZUI_IOS_SIMULATOR_SDK")
    end
  end

  def test_physical_iphone_runtime_uses_arm64_device_target
    Dir.mktmpdir do |directory|
      dependencies = create_dependencies(directory)
      build_name = "zui-ios-device-arm64-bytecode"
      command = RuntimeBuildCommand.new(dependencies.fetch(:mruby), build_name)
      builder = Zui::Mobile::IOSBuilder.new(
        project: directory, framework_root: ROOT, command:,
        qt_ios: dependencies.fetch(:qt_ios), qt_host: dependencies.fetch(:qt_host),
        mruby_root: dependencies.fetch(:mruby), mruby_json: dependencies.fetch(:mruby_json),
        device: "DEVICE", team: "TEAM", host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )

      builder.send(:build_mruby, "/iPhone.sdk", build_name, platform: "device")

      _arguments, options = command.calls.fetch(0)
      assert_equal "arm64", options.dig(:env, "ZUI_IOS_ARCH")
      assert_equal "device", options.dig(:env, "ZUI_IOS_PLATFORM")
      assert_equal "/iPhone.sdk", options.dig(:env, "ZUI_IOS_SDK")
    end
  end

  def test_physical_iphone_requires_an_apple_team
    Dir.mktmpdir do |directory|
      dependencies = create_dependencies(directory)
      create_project(directory)
      builder = Zui::Mobile::IOSBuilder.new(
        project: directory, framework_root: ROOT, device: "DEVICE",
        qt_ios: dependencies.fetch(:qt_ios), qt_host: dependencies.fetch(:qt_host),
        mruby_root: dependencies.fetch(:mruby), mruby_json: dependencies.fetch(:mruby_json),
        environment: {}, host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )

      error = assert_raises(ArgumentError) { builder.send(:validate!) }

      assert_includes error.message, "--team"
    end
  end

  private

  def create_dependencies(directory)
    qt_ios = File.join(directory, "qt", "ios")
    qt_host = File.join(directory, "qt", "macos")
    mruby = File.join(directory, "mruby")
    mruby_json = File.join(directory, "mruby-json")
    [File.join(qt_ios, "bin"), qt_host, mruby, mruby_json].each { |path| FileUtils.mkdir_p(path) }
    File.write(File.join(qt_ios, "bin", "qt-cmake"), "")
    File.write(File.join(mruby, "minirake"), "")
    File.write(File.join(mruby_json, "mrbgem.rake"), "")
    { qt_ios:, qt_host:, mruby:, mruby_json: }
  end

  def create_project(project)
    FileUtils.mkdir_p(File.join(project, "assets"))
    File.write(File.join(project, "main.rb"), <<~RUBY)
      require "zui"
      Zui.app do
        app :main do
          text "Touch ready"
        end
      end
    RUBY
    icon = File.join(ROOT, "lib", "zui", "generator_assets", "ruby.png")
    FileUtils.cp(icon, File.join(project, "assets", "ruby.png"))
    File.write(File.join(project, "config.rb"), <<~RUBY)
      Zui::Dist.configure do
        name "Touch Test"
        identifier "dev.zui.touch-test"
        version "0.1.0"
        publisher "Zui"
        description "A mobile test application."
        license "MIT"
        icon ios: "assets/ruby.png"
        categories "Utility"
      end
    RUBY
  end
end
