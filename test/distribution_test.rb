# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class DistributionTest < Minitest::Test
  FakeHost = Struct.new(:path) do
    def executable = path
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

  def test_windows_bundle_has_native_host_runtime_and_safe_launchers
    with_project do |project, host|
      platform = Zui::Platform.new(os: :windows, arch: :x86_64)
      destination = Zui::Distribution.new(host: FakeHost.new(host), platform:).bundle(project)

      assert File.file?(File.join(destination, "run.cmd"))
      assert File.file?(File.join(destination, "run.rb"))
      assert File.file?(File.join(destination, "bin", "zui-host.exe"))
      assert File.file?(File.join(destination, "app", "main.rb"))
      assert File.file?(File.join(destination, "runtime", "lib", "zui.rb"))
      assert File.file?(File.join(destination, "runtime", "qml", "Desktop.qml"))
      assert_equal "windows", JSON.parse(File.read(File.join(destination, "zui-bundle.json"))).fetch("platform")
      assert_includes File.read(File.join(destination, "run.cmd")), "%ZUI_RUBY%"
      assert_includes File.read(File.join(destination, "run.rb")), 'exec(*arguments)'
      refute_includes File.read(File.join(destination, "run.rb")), "Omarchy"
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
