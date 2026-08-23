# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class DistributionTest < Minitest::Test
  FakeHost = Struct.new(:path) do
    def executable = path
  end

  def test_validator_builds_a_real_ruby_render_tree
    result = Zui::Validator.new.validate(File.join(__dir__, "fixtures", "smoke_app.rb"))

    assert result.valid?, result.errors.join("\n")
    assert_equal ["main"], result.surfaces
  end

  def test_linux_bundle_contains_portable_app_runtime_and_desktop_entry
    with_project do |project, host|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      destination = Zui::Distribution.new(host: FakeHost.new(host), platform:).bundle(project)

      assert File.executable?(File.join(destination, "run"))
      assert File.executable?(File.join(destination, "bin", "zui-host"))
      assert File.file?(File.join(destination, "app", "main.rb"))
      assert File.file?(File.join(destination, "runtime", "lib", "zui.rb"))
      assert File.file?(File.join(destination, "runtime", "qml", "Desktop.qml"))
      assert_equal "linux", JSON.parse(File.read(File.join(destination, "zui-bundle.json"))).fetch("platform")
      assert_equal 1, Dir[File.join(destination, "share", "applications", "*.desktop")].length
      assert_includes File.read(File.join(destination, "run")), '${ZUI_RUBY:-ruby}'
    end
  end

  def test_macos_bundle_has_a_standard_application_layout
    with_project do |project, host|
      platform = Zui::Platform.new(os: :macos, arch: :arm64)
      destination = File.join(project, "package", "Demo.app")
      Zui::Distribution.new(host: FakeHost.new(host), platform:).bundle(project, destination:)

      contents = File.join(destination, "Contents")
      assert File.executable?(File.join(contents, "MacOS", "run"))
      assert File.executable?(File.join(contents, "MacOS", "zui-host"))
      assert File.file?(File.join(contents, "Info.plist"))
      assert File.file?(File.join(contents, "Resources", "app", "main.rb"))
      assert File.file?(File.join(contents, "Resources", "runtime", "qml", "Desktop.qml"))
      assert_includes File.read(File.join(contents, "Info.plist")), "CFBundlePackageType"
    end
  end

  private

  def with_project
    Dir.mktmpdir do |directory|
      project = File.join(directory, "demo")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "main.rb"), File.read(File.join(__dir__, "fixtures", "smoke_app.rb")))
      File.write(File.join(project, "asset.txt"), "owned by app")
      host = File.join(directory, "zui-host")
      File.write(host, "host")
      FileUtils.chmod(0o755, host)
      yield project, host
    end
  end
end
