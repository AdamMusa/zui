# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class PlatformTest < Minitest::Test
  def test_detects_supported_linux_and_macos_architectures
    assert_equal "linux-x86_64", Zui::Platform.detect("linux-gnu", "amd64").id
    assert_equal "linux-arm64", Zui::Platform.detect("linux", "aarch64").id
    assert_equal "macos-arm64", Zui::Platform.detect("darwin23", "arm64").id
  end

  def test_rejects_unsupported_desktop_platforms
    platform = Zui::Platform.detect("mingw32", "x86_64")

    refute platform.supported?
    assert_raises(ArgumentError) { platform.assert_supported! }
  end
end
