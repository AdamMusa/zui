# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class PlatformTest < Minitest::Test
  def test_detects_supported_desktop_platforms_and_architectures
    assert_equal "linux-x86_64", Zui::Platform.detect("linux-gnu", "amd64").id
    assert_equal "linux-arm64", Zui::Platform.detect("linux", "aarch64").id
    assert_equal "macos-arm64", Zui::Platform.detect("darwin23", "arm64").id
    assert_equal "macos-x86_64", Zui::Platform.detect("darwin22", "x86_64").id
    assert_equal "windows-x86_64", Zui::Platform.detect("mingw-ucrt", "x64-mingw-ucrt").id
    assert_equal "windows-arm64", Zui::Platform.detect("mswin", "ARM64").id
  end

  def test_rejects_unsupported_desktop_platforms
    platform = Zui::Platform.detect("freebsd14", "x86_64")

    refute platform.supported?
    assert_raises(ArgumentError) { platform.assert_supported! }
  end
end
