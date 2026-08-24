# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class HostTest < Minitest::Test
  def test_uses_native_cache_roots_on_every_supported_platform
    Dir.mktmpdir do |home|
      linux = host_for(:linux, home:, "XDG_CACHE_HOME" => File.join(home, "xdg"))
      macos = host_for(:macos, home:)
      windows = host_for(:windows, home:, "LOCALAPPDATA" => File.join(home, "Local"))

      assert_equal File.join(home, "xdg", "zui", "host", Zui::VERSION, "linux-x86_64", "zui-host"),
                   linux.send(:cached)
      assert_equal File.join(home, "Library", "Caches", "zui", "host", Zui::VERSION,
                             "macos-x86_64", "zui-host"), macos.send(:cached)
      assert_equal File.join(home, "Local", "zui", "host", Zui::VERSION,
                             "windows-x86_64", "zui-host.exe"), windows.send(:cached)
    end
  end

  def test_windows_build_help_names_the_required_native_toolchain
    host = host_for(:windows, home: Dir.home)

    assert_includes host.platform_help, "Windows"
    assert_includes host.platform_help, "CMake"
    assert_includes host.platform_help, "Qt 6"
  end

  def test_windows_command_lookup_honors_pathext
    Dir.mktmpdir do |directory|
      executable = File.join(directory, "cmake.exe")
      File.write(executable, "binary")
      FileUtils.chmod(0o755, executable)
      host = host_for(:windows, home: directory, "PATH" => directory, "PATHEXT" => ".EXE;.CMD")

      assert_equal executable, host.send(:find_command, "cmake")
    end
  end

  private

  def host_for(os, home:, **environment)
    platform = Zui::Platform.new(os:, arch: :x86_64)
    Zui::Host.new(platform:, framework_root: File.expand_path("..", __dir__),
                  environment: { "HOME" => home, "USERPROFILE" => home }.merge(environment))
  end
end
