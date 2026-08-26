# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class MobileSetupTest < Minitest::Test
  def test_enable_persists_mobile_support_without_installing_dependencies
    Dir.mktmpdir do |directory|
      config = File.join(directory, "config.json")
      setup = Zui::Mobile::Setup.new(config_path: config, environment: { "ZUI_MOBILE_HOME" => directory })

      refute setup.enabled?
      setup.enable!

      assert setup.enabled?
      assert_equal true, JSON.parse(File.read(config)).fetch("enabled")
    end
  end

  def test_prepare_project_creates_editable_android_and_ios_configuration
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "main.rb"), "require \"zui\"\n")
      File.write(File.join(project, "config.rb"), "Zui::Dist.configure {}\n")
      setup = Zui::Mobile::Setup.new(
        config_path: File.join(directory, "config.json"),
        environment: { "ZUI_MOBILE_HOME" => directory }
      )

      directories = setup.prepare_project!(project)

      assert_equal [File.join(project, "android"), File.join(project, "ios")], directories
      manifest = File.read(File.join(project, "android", "AndroidManifest.xml"))
      info_plist = File.read(File.join(project, "ios", "Info.plist.in"))
      assert_includes manifest, "%%INSERT_PERMISSIONS"
      assert_includes manifest, "QtActivity"
      assert_includes info_plist, "NSCameraUsageDescription"
      assert File.file?(File.join(project, "ios", "Zui.entitlements"))
      assert File.file?(File.join(project, "ios", "Zui.cmake"))
      assert File.file?(File.join(project, "ios", "Zui.xcconfig"))
      assert File.file?(File.join(project, "ios", "Resources", "README.md"))
      assert File.file?(File.join(project, "ios", "Sources", "README.md"))
      assert File.file?(File.join(project, "ios", "Frameworks", "README.md"))
      assert File.file?(File.join(project, "android", "zui.gradle"))
      assert File.file?(File.join(project, "android", "Zui.cmake"))
      assert File.file?(File.join(project, "android", "README.md"))
      assert File.file?(File.join(project, "ios", "README.md"))
    end
  end

  def test_prepare_project_fills_missing_files_without_overwriting_custom_configuration
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "main.rb"), "require \"zui\"\n")
      File.write(File.join(directory, "config.rb"), "Zui::Dist.configure {}\n")
      FileUtils.mkdir_p(File.join(directory, "android"))
      manifest = File.join(directory, "android", "AndroidManifest.xml")
      File.write(manifest, "custom manifest\n")
      setup = Zui::Mobile::Setup.new(
        config_path: File.join(directory, "mobile.json"),
        environment: { "ZUI_MOBILE_HOME" => directory }
      )

      setup.prepare_project!(directory)

      assert_equal "custom manifest\n", File.read(manifest)
      assert File.file?(File.join(directory, "android", "README.md"))
      assert File.file?(File.join(directory, "ios", "Info.plist.in"))
    end
  end

  def test_prepare_project_requires_a_complete_zui_project
    Dir.mktmpdir do |directory|
      setup = Zui::Mobile::Setup.new(
        config_path: File.join(directory, "mobile.json"),
        environment: { "ZUI_MOBILE_HOME" => directory }
      )

      error = assert_raises(ArgumentError) { setup.prepare_project!(directory) }

      assert_includes error.message, "main.rb"
    end
  end

  def test_fix_records_detected_ios_and_android_dependencies
    Dir.mktmpdir do |directory|
      paths = dependency_paths(directory)
      environment = dependency_environment(directory, paths).merge("ZUI_APPLE_TEAM" => "TEAM123456")
      config = File.join(directory, "mobile-config.json")
      setup = Zui::Mobile::Setup.new(
        config_path: config, environment:,
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )

      values = setup.fix!

      assert_equal true, values.fetch("enabled")
      assert_equal paths.fetch(:qt_ios), values.fetch("qt_ios")
      assert_equal paths.fetch(:qt_android), values.fetch("qt_android")
      assert_equal paths.fetch(:android_ndk), values.fetch("android_ndk")
      assert_equal "TEAM123456", values.fetch("apple_team")
      assert_equal values, JSON.parse(File.read(config))
    end
  end

  def test_dependencies_use_persisted_paths_and_team_after_environment_changes
    Dir.mktmpdir do |directory|
      paths = dependency_paths(directory)
      config = File.join(directory, "mobile-config.json")
      first = Zui::Mobile::Setup.new(
        config_path: config,
        environment: dependency_environment(directory, paths).merge("ZUI_APPLE_TEAM" => "TEAM123456"),
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )
      first.fix!

      setup = Zui::Mobile::Setup.new(
        config_path: config, environment: { "ZUI_MOBILE_HOME" => directory },
        host_platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )
      dependencies = setup.dependencies(:ios)

      assert_equal paths.fetch(:qt_host), dependencies.fetch("qt_host")
      assert_equal paths.fetch(:mruby), dependencies.fetch("mruby_root")
      assert_equal "TEAM123456", dependencies.fetch("apple_team")
    end
  end

  def test_dependencies_require_mobile_to_be_enabled
    Dir.mktmpdir do |directory|
      setup = Zui::Mobile::Setup.new(
        config_path: File.join(directory, "config.json"),
        environment: { "ZUI_MOBILE_HOME" => directory }
      )

      error = assert_raises(ArgumentError) { setup.dependencies(:android) }

      assert_includes error.message, "zui mobile --enable"
    end
  end

  private

  def dependency_paths(directory)
    paths = {
      qt_host: File.join(directory, "Qt", "macos"),
      qt_ios: File.join(directory, "Qt", "ios"),
      qt_android: File.join(directory, "Qt", "android_arm64_v8a"),
      mruby: File.join(directory, "src", "mruby"),
      mruby_json: File.join(directory, "src", "mruby-json"),
      android_sdk: File.join(directory, "android-sdk")
    }
    paths[:android_ndk] = File.join(paths.fetch(:android_sdk), "ndk", Zui::Mobile::Setup::NDK_VERSION)
    paths.each_value { |path| FileUtils.mkdir_p(path) }
    paths
  end

  def dependency_environment(directory, paths)
    {
      "ZUI_MOBILE_HOME" => directory,
      "ZUI_QT_HOST" => paths.fetch(:qt_host),
      "ZUI_QT_IOS" => paths.fetch(:qt_ios),
      "ZUI_QT_ANDROID" => paths.fetch(:qt_android),
      "ZUI_MRUBY_ROOT" => paths.fetch(:mruby),
      "ZUI_MRUBY_JSON" => paths.fetch(:mruby_json),
      "ANDROID_SDK_ROOT" => paths.fetch(:android_sdk),
      "ANDROID_NDK_ROOT" => paths.fetch(:android_ndk)
    }
  end
end
