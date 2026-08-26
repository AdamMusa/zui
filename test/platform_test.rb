# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class PlatformTest < Minitest::Test
  def test_detects_supported_platforms_and_architectures
    assert_equal "linux-x86_64", Zui::Platform.detect("linux-gnu", "amd64").id
    assert_equal "linux-arm64", Zui::Platform.detect("linux", "aarch64").id
    assert_equal "macos-arm64", Zui::Platform.detect("darwin23", "arm64").id
    assert_equal "macos-x86_64", Zui::Platform.detect("darwin22", "x86_64").id
    assert_equal "windows-x86_64", Zui::Platform.detect("mingw-ucrt", "x64-mingw-ucrt").id
    assert_equal "windows-arm64", Zui::Platform.detect("mswin", "ARM64").id
    assert_equal "android-arm64", Zui::Platform.detect("linux-android", "aarch64").id
    assert_equal "ios-arm64", Zui::Platform.detect("iphoneos", "arm64").id
    refute Zui::Platform.detect("linux-android", "aarch64").supported?
    assert Zui::Platform.detect("iphoneos", "arm64").supported?
    assert Zui::Platform.new(os: :ios, arch: :arm64).mobile?
    assert Zui::Platform.new(os: :linux, arch: :x86_64).desktop?
  end

  def test_rejects_unsupported_platforms
    platform = Zui::Platform.detect("freebsd14", "x86_64")

    refute platform.supported?
    assert_raises(ArgumentError) { platform.assert_supported! }
  end
end
