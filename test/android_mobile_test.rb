# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/zui"

class AndroidMobileTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  SuccessfulStatus = Struct.new(:exitstatus) do
    def success? = true
  end

  def test_android_stage_contains_bytecode_source_assets_icon_and_manifest
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      create_project(project)
      Zui::Mobile::Setup.new(
        config_path: File.join(directory, "mobile.json"),
        environment: { "ZUI_MOBILE_HOME" => directory }
      ).prepare_project!(project)
      manifest_path = File.join(project, "android", "AndroidManifest.xml")
      manifest = File.read(manifest_path).sub(
        "    <!-- %%INSERT_PERMISSIONS -->",
        "    <uses-permission android:name=\"android.permission.CAMERA\" />\n    <!-- %%INSERT_PERMISSIONS -->"
      )
      File.write(manifest_path, manifest)
      java = File.join(project, "android", "src", "dev", "zui", "MobileBridge.java")
      FileUtils.mkdir_p(File.dirname(java))
      File.write(java, "package dev.zui; class MobileBridge {}\n")
      File.write(File.join(project, "android", "zui.gradle"), <<~GRADLE)
        dependencies {
            implementation 'provider.example:mobile-sdk:1.0.0'
        }
      GRADLE
      builder = create_builder(project, dependencies, output: File.join(directory, "build"))

      builder.send(:validate!)
      config = Zui::Dist.load(project:, platform: Zui::Mobile::AndroidBuilder::ANDROID_PLATFORM)
      stage = builder.send(:prepare_stage, config)

      source = File.read(File.join(stage, "app.rb"))
      manifest = File.read(File.join(stage, "android", "AndroidManifest.xml"))
      styles = File.read(File.join(stage, "android", "res", "values", "styles.xml"))
      assert_includes source, 'text "Touch ready"'
      assert_includes manifest, "org.qtproject.qt.android.bindings.QtActivity"
      assert_includes manifest, "android.permission.CAMERA"
      assert_includes manifest, "%%INSERT_PERMISSIONS"
      assert_includes manifest, "@drawable/zui_icon"
      assert_includes styles, "#07110d"
      assert File.file?(File.join(stage, "android", "res", "drawable", "zui_icon.png"))
      assert File.file?(File.join(stage, "android", "res", "drawable", "zui_splash.png"))
      assert_includes styles, "@drawable/zui_launch_background"
      gradle = File.read(File.join(stage, "android", "build.gradle"))
      assert_includes gradle, "apply plugin: qtGradlePluginType"
      assert_includes gradle, "apply from: 'zui.gradle'"
      assert_includes File.read(File.join(stage, "android", "zui.gradle")), "mobile-sdk"
      assert File.file?(File.join(stage, "android", "src", "dev", "zui", "MobileBridge.java"))
      assert_equal File.binread(File.join(project, "assets", "ruby.png")),
                   File.binread(File.join(stage, "assets", "ruby.png"))
    end
  end

  def test_android_overlay_rejects_a_manifest_missing_qt_markers
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      create_project(project)
      FileUtils.mkdir_p(File.join(project, "android"))
      File.write(File.join(project, "android", "AndroidManifest.xml"), "<manifest />\n")
      builder = create_builder(project, dependencies, output: File.join(directory, "build"))
      config = Zui::Dist.load(project:, platform: Zui::Mobile::AndroidBuilder::ANDROID_PLATFORM)

      error = assert_raises(ArgumentError) { builder.send(:prepare_stage, config) }

      assert_includes error.message, "Qt activity"
      assert_includes error.message, "permission marker"
    end
  end

  def test_android_identifier_normalizes_ios_safe_hyphens
    Dir.mktmpdir do |directory|
      dependencies = create_dependencies(directory)
      builder = create_builder(directory, dependencies)

      assert_equal "dev.zui.mobile_counter", builder.send(:android_identifier, "dev.zui.mobile-counter")
      assert_equal "dev.app_123.counter", builder.send(:android_identifier, "dev.123.counter")
    end
  end

  def test_android_builder_rejects_api_levels_older_than_23
    Dir.mktmpdir do |directory|
      dependencies = create_dependencies(directory)
      create_project(directory)
      builder = create_builder(directory, dependencies, api: 22)

      error = assert_raises(ArgumentError) { builder.send(:validate!) }

      assert_includes error.message, "at least 23"
    end
  end

  def test_android_configuration_exposes_the_project_native_hook
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      create_project(project)
      calls = []
      command = Object.new
      command.define_singleton_method(:run) do |arguments, **options|
        calls << [arguments, options]
        Zui::CommandResult.new(stdout: "", stderr: "", status: SuccessfulStatus.new(0))
      end
      builder = create_builder(
        project, dependencies, command:, output: File.join(directory, "build")
      )
      config = Zui::Dist.load(project:, platform: Zui::Mobile::AndroidBuilder::ANDROID_PLATFORM)

      builder.send(:configure_native, config, "dev.zui.touch_test", File.join(directory, "stage"), "runtime")

      arguments = calls.fetch(0).fetch(0)
      assert_includes arguments, "-DZUI_ANDROID_PROJECT_DIR=#{File.join(project, 'android')}"
    end
  end

  def test_android_install_target_distinguishes_emulators_from_physical_devices
    Dir.mktmpdir do |directory|
      dependencies = create_dependencies(directory)
      adb = File.join(dependencies.fetch(:android_sdk), "platform-tools", "adb")
      command = Object.new
      command.define_singleton_method(:run) do |arguments, **_options|
        output = if arguments == [adb, "devices"]
                   "List of devices attached\nemulator-5554\tdevice\nPHONE123\tdevice\n"
                 elsif arguments.last == "ro.kernel.qemu"
                   arguments[2] == "emulator-5554" ? "1\n" : "0\n"
                 elsif arguments.last == "ro.product.cpu.abilist"
                   "arm64-v8a,armeabi-v7a\n"
                 else
                   ""
                 end
        Zui::CommandResult.new(stdout: output, stderr: "", status: SuccessfulStatus.new(0))
      end

      physical = create_builder(directory, dependencies, command:, device_kind: :physical, out: StringIO.new)
      emulator = create_builder(directory, dependencies, command:, device_kind: :emulator, out: StringIO.new)

      assert_equal "PHONE123", physical.send(:select_device)
      assert_equal "emulator-5554", emulator.send(:select_device)
    end
  end

  private

  def create_builder(project, dependencies, **options)
    Zui::Mobile::AndroidBuilder.new(
      project:, framework_root: ROOT,
      qt_android: dependencies.fetch(:qt_android), qt_host: dependencies.fetch(:qt_host),
      android_sdk: dependencies.fetch(:android_sdk), android_ndk: dependencies.fetch(:android_ndk),
      mruby_root: dependencies.fetch(:mruby), mruby_json: dependencies.fetch(:mruby_json),
      host_platform: Zui::Platform.new(os: :macos, arch: :arm64), **options
    )
  end

  def create_dependencies(directory)
    qt_android = File.join(directory, "qt", "android_arm64_v8a")
    qt_host = File.join(directory, "qt", "macos")
    android_sdk = File.join(directory, "android-sdk")
    android_ndk = File.join(android_sdk, "ndk", "27.0.12077973")
    mruby = File.join(directory, "mruby")
    mruby_json = File.join(directory, "mruby-json")
    files = [
      File.join(qt_android, "bin", "qt-cmake"), File.join(qt_host, "bin", "androiddeployqt"),
      File.join(qt_android, "src", "android", "templates", "build.gradle"),
      File.join(android_sdk, "platform-tools", "adb"),
      File.join(android_ndk, "build", "cmake", "android.toolchain.cmake"),
      File.join(mruby, "minirake"), File.join(mruby_json, "mrbgem.rake")
    ]
    files.each do |path|
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "")
    end
    File.write(
      File.join(qt_android, "src", "android", "templates", "build.gradle"),
      "apply plugin: qtGradlePluginType\n"
    )
    { qt_android:, qt_host:, android_sdk:, android_ndk:, mruby:, mruby_json: }
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
        icon android: "assets/ruby.png"
        splash android: "assets/ruby.png"
        categories "Utility"
      end
    RUBY
  end
end
