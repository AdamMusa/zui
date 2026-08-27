# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/zui"

class MobileTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  MobileGemSpec = Struct.new(
    :name, :version, :full_gem_path, :require_paths, :platform, :extensions, :files, :default,
    keyword_init: true
  ) do
    def full_name = "#{name}-#{version}"
    def default_gem? = default == true
    def to_ruby(files: self.files)
      "Gem::Specification.new { |spec| spec.name = #{name.dump}; spec.version = #{version.dump}; " \
        "spec.files = #{files.inspect} }\n"
    end
  end

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

  class XcodeConfigureCommand
    attr_reader :calls

    def initialize
      @calls = []
    end

    def run(arguments, **options)
      @calls << [arguments, options]
      build = arguments.fetch(arguments.index("-B") + 1)
      FileUtils.mkdir_p(File.join(build, "zui-host.xcodeproj"))
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
      refute File.exist?(File.join(stage, "assets", "ruby.png"))
      refute File.exist?(File.join(stage, "assets", "release.ico"))
      assert_equal "runtime asset", File.read(File.join(stage, "assets", "runtime.txt"))
      assert_equal "AppIcon.png", manifest.dig("images", 0, "filename")
      assert File.file?(File.join(stage, "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png"))
      assert File.file?(File.join(stage, "Assets.xcassets", "ZuiSplash.imageset", "ZuiSplash.png"))
      assert_includes File.read(File.join(stage, "LaunchScreen.storyboard")), "ZuiSplash"
    end
  end

  def test_ios_builder_rejects_non_macos_hosts
    builder = Zui::Mobile::IOSBuilder.new(
      project: ".", host_platform: Zui::Platform.new(os: :linux, arch: :x86_64)
    )

    error = assert_raises(ArgumentError) { builder.send(:validate!) }

    assert_includes error.message, "must be built on macOS"
  end

  def test_ios_configuration_uses_project_plist_entitlements_and_launch_screen
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      create_project(project)
      Zui::Mobile::Setup.new(
        config_path: File.join(directory, "mobile.json"),
        environment: { "ZUI_MOBILE_HOME" => directory }
      ).prepare_project!(project)
      launch_screen = File.join(project, "ios", "LaunchScreen.storyboard")
      File.write(launch_screen, "custom launch screen")
      command = XcodeConfigureCommand.new
      output = File.join(directory, "build")
      builder = Zui::Mobile::IOSBuilder.new(
        project:, output:, framework_root: ROOT, command:,
        qt_ios: dependencies.fetch(:qt_ios), qt_host: dependencies.fetch(:qt_host),
        mruby_root: dependencies.fetch(:mruby), mruby_json: dependencies.fetch(:mruby_json),
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )
      config = Zui::Dist.load(project:, platform: Zui::Mobile::IOSBuilder::IOS_PLATFORM)

      builder.send(:configure_xcode, config, File.join(output, "stage"), "runtime", sdk: "/Simulator.sdk")

      arguments = command.calls.fetch(0).fetch(0)
      assert_includes arguments, "-DCMAKE_OSX_SYSROOT=/Simulator.sdk"
      assert_includes arguments, "-DCMAKE_OSX_ARCHITECTURES=x86_64"
      assert_includes arguments, "-DZUI_IOS_INFO_PLIST=#{File.join(project, 'ios', 'Info.plist.in')}"
      assert_includes arguments, "-DZUI_IOS_ENTITLEMENTS=#{File.join(project, 'ios', 'Zui.entitlements')}"
      assert_includes arguments, "-DZUI_IOS_PROJECT_DIR=#{File.join(project, 'ios')}"
      assert_includes arguments, "-DZUI_IOS_LAUNCH_SCREEN=#{launch_screen}"
    end
  end

  def test_ios_full_runtime_stages_cruby_json_and_configures_native_embedding
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      cruby = create_cruby_dependencies(directory)
      create_project(project)
      paint = create_mobile_gem(directory, "paint", "1.2.3")
      File.write(File.join(project, "main.rb"), <<~RUBY)
        require "zui"
        require "paint"
        Zui.app do
          app :main do
            text Paint.label
          end
        end
      RUBY
      command = XcodeConfigureCommand.new
      output = File.join(directory, "build")
      builder = Zui::Mobile::IOSBuilder.new(
        project:, output:, framework_root: ROOT, command:, runtime_mode: :full,
        qt_ios: dependencies.fetch(:qt_ios), qt_host: dependencies.fetch(:qt_host),
        cruby_source_root: cruby.fetch(:source), cruby_build_root: cruby.fetch(:build),
        gem_spec_loader: ->(_project) { [paint] },
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )

      builder.send(:validate!)
      config = Zui::Dist.load(project:, platform: Zui::Mobile::IOSBuilder::IOS_PLATFORM)
      stage = builder.send(:prepare_stage, config)
      builder.send(:copy_cruby_support, stage)
      builder.send(:configure_xcode, config, stage, "unused", sdk: "/Simulator.sdk")

      assert_equal "json common", File.read(File.join(stage, "cruby", "json", "common.rb"))
      assert_equal "json state", File.read(File.join(stage, "cruby", "json", "ext", "generator", "state.rb"))
      assert_equal "uri support", File.read(File.join(stage, "cruby", "stdlib", "source", "uri.rb"))
      assert_equal "target rbconfig", File.read(File.join(stage, "cruby", "stdlib", "generated", "rbconfig.rb"))
      %w[version.rb common.rb ext.rb ext/generator/state.rb].each do |relative|
        refute File.exist?(File.join(stage, "cruby", "stdlib", "generated", "json", relative))
      end
      assert_equal "module Paint; def self.label = 'Paint ready'; end\n",
                   File.read(File.join(stage, "cruby", "gems", "paint-1.2.3", "lib", "paint.rb"))
      assert File.file?(File.join(stage, "cruby", "specifications", "paint-1.2.3.gemspec"))
      refute File.exist?(File.join(stage, "cruby", "gems", "paint-1.2.3", "dist"))
      assert_includes File.read(File.join(stage, "app.rb")), 'require "paint"'
      gem_manifest = JSON.parse(File.read(File.join(stage, "cruby", "gems.json")))
      assert_match(/\A[0-9a-f]{64}\z/, gem_manifest.fetch("digest"))
      assert_equal %w[stdlib/generated stdlib/source], gem_manifest.fetch("standard_library_paths")
      assert_equal ["gems/paint-1.2.3/lib"], gem_manifest.dig("gems", 0, "load_paths")
      arguments = command.calls.fetch(0).fetch(0)
      assert_includes arguments, "-DZUI_EMBEDDED_CRUBY=ON"
      assert_includes arguments, "-DZUI_CRUBY_SOURCE_ROOT=#{cruby.fetch(:source)}"
      assert_includes arguments, "-DZUI_CRUBY_BUILD_ROOT=#{cruby.fetch(:build)}"
      refute arguments.any? { |argument| argument.start_with?("-DZUI_MRUBY_ROOT=") }
    end
  end

  def test_ios_full_runtime_rejects_dynamic_native_gems
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      create_project(project)
      native = create_mobile_gem(directory, "native-paint", "2.0.0", extensions: ["ext/paint/extconf.rb"])
      builder = Zui::Mobile::IOSBuilder.new(
        project:, runtime_mode: :full, gem_spec_loader: ->(_project) { [native] },
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )
      stage = File.join(directory, "stage")
      FileUtils.mkdir_p(stage)

      error = assert_raises(ArgumentError) { builder.send(:copy_project_gems, stage) }

      assert_includes error.message, "cannot dynamically load native gem native-paint-2.0.0"
      assert_includes error.message, "iOS static extension"
    end
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

  def test_physical_iphone_can_be_auto_selected_from_xcode_destinations
    command = Object.new
    command.define_singleton_method(:run) do |_arguments, **_options|
      output = <<~OUTPUT
        Available destinations:
          { platform:iOS, arch:arm64, id:PHONE-UDID, name:Liveview }
          { platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
      OUTPUT
      Zui::CommandResult.new(stdout: output, stderr: "", status: SuccessfulStatus.new(0))
    end
    builder = Zui::Mobile::IOSBuilder.new(
      project: ".", device: "auto", team: "TEAM", command:,
      host_platform: Zui::Platform.new(os: :macos, arch: :arm64), out: StringIO.new
    )

    assert_equal "PHONE-UDID", builder.send(:select_physical_device, "/tmp/Zui.xcodeproj")
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
    File.write(File.join(project, "assets", "release.ico"), "desktop release icon")
    File.write(File.join(project, "assets", "runtime.txt"), "runtime asset")
    File.write(File.join(project, "config.rb"), <<~RUBY)
      Zui::Dist.configure do
        name "Touch Test"
        identifier "dev.zui.touch-test"
        version "0.1.0"
        publisher "Zui"
        description "A mobile test application."
        license "MIT"
        icon ios: "assets/ruby.png", windows: "assets/release.ico"
        splash ios: "assets/ruby.png"
        categories "Utility"
      end
    RUBY
  end

  def create_cruby_dependencies(directory)
    source = File.join(directory, "cruby-source")
    build = File.join(directory, "cruby-build")
    files = {
      File.join(source, "include", "ruby.h") => "ruby",
      File.join(source, "lib", "uri.rb") => "uri support",
      File.join(build, "libruby.4.0-static.a") => "runtime",
      File.join(build, "rbconfig.rb") => "target rbconfig",
      File.join(build, "ext", "json", "generator", "generator.a") => "generator",
      File.join(build, "ext", "json", "parser", "parser.a") => "parser",
      File.join(build, "enc", "libenc.a") => "encodings",
      File.join(build, ".ext", "common", "json", "version.rb") => "json version",
      File.join(build, ".ext", "common", "json", "common.rb") => "json common",
      File.join(build, ".ext", "common", "json", "ext.rb") => "json ext",
      File.join(build, ".ext", "common", "json", "ext", "generator", "state.rb") => "json state"
    }
    %w[
      continuation/continuation.a coverage/coverage.a date/date_core.a digest/digest.a
      etc/etc.a fcntl/fcntl.a io/nonblock/nonblock.a io/wait/wait.a monitor/monitor.a
      objspace/objspace.a rbconfig/sizeof/sizeof.a stringio/stringio.a strscan/strscan.a
    ].each do |relative|
      files[File.join(build, "ext", relative)] = "standard extension"
    end
    files.each do |path, content|
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
    { source:, build: }
  end

  def create_mobile_gem(directory, name, version, extensions: [])
    root = File.join(directory, "installed-gems", "#{name}-#{version}")
    FileUtils.mkdir_p([File.join(root, "lib"), File.join(root, "dist")])
    File.write(File.join(root, "lib", "#{name.tr('-', '_')}.rb"),
               "module Paint; def self.label = 'Paint ready'; end\n")
    File.write(File.join(root, "dist", "development.bin"), "must not ship")
    MobileGemSpec.new(
      name:, version:, full_gem_path: root, require_paths: ["lib"],
      platform: "ruby", extensions:, files: ["lib/#{name.tr('-', '_')}.rb"]
    )
  end
end
