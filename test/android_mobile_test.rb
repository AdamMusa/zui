# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class AndroidMobileTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_android_stage_contains_bytecode_source_assets_icon_and_manifest
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      dependencies = create_dependencies(directory)
      create_project(project)
      builder = create_builder(project, dependencies, output: File.join(directory, "build"))

      builder.send(:validate!)
      config = Zui::Dist.load(project:, platform: Zui::Mobile::AndroidBuilder::ANDROID_PLATFORM)
      stage = builder.send(:prepare_stage, config)

      source = File.read(File.join(stage, "app.rb"))
      manifest = File.read(File.join(stage, "android", "AndroidManifest.xml"))
      styles = File.read(File.join(stage, "android", "res", "values", "styles.xml"))
      assert_includes source, 'text "Touch ready"'
      assert_includes manifest, "org.qtproject.qt.android.bindings.QtActivity"
      assert_includes manifest, "@drawable/zui_icon"
      assert_includes styles, "#07110d"
      assert File.file?(File.join(stage, "android", "res", "drawable", "zui_icon.png"))
      assert_equal File.binread(File.join(project, "assets", "ruby.png")),
                   File.binread(File.join(stage, "assets", "ruby.png"))
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
      File.join(android_sdk, "platform-tools", "adb"),
      File.join(android_ndk, "build", "cmake", "android.toolchain.cmake"),
      File.join(mruby, "minirake"), File.join(mruby_json, "mrbgem.rake")
    ]
    files.each do |path|
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "")
    end
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
        categories "Utility"
      end
    RUBY
  end
end
