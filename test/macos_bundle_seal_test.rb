# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class MacOSBundleSealTest < Minitest::Test
  Result = Struct.new(:stdout, :stderr, :successful, keyword_init: true) do
    def success? = successful
  end

  class FakeCodesign
    attr_reader :calls

    def initialize(successful: true)
      @successful = successful
      @calls = []
    end

    def run(arguments, **)
      @calls << arguments
      Result.new(stdout: "", stderr: @successful ? "" : "invalid framework", successful: @successful)
    end
  end

  def test_restores_safe_framework_links_and_ad_hoc_seals_the_pruned_host
    Dir.mktmpdir do |native|
      framework = framework_fixture(native)
      command = FakeCodesign.new

      application = Zui::MacOSBundleSeal.seal!(native, command:)

      assert_equal File.join(native, "zui-host.app"), application
      assert_equal "A", File.readlink(File.join(framework, "Versions", "Current"))
      assert_equal "Versions/Current/QtCore", File.readlink(File.join(framework, "QtCore"))
      assert_equal "Versions/Current/Resources", File.readlink(File.join(framework, "Resources"))
      assert_equal ["codesign", "--force", "--deep", "--sign", "-", "--timestamp=none", application],
                   command.calls.fetch(0)
    end
  end

  def test_rejects_an_unexpected_existing_framework_link
    Dir.mktmpdir do |native|
      framework = framework_fixture(native)
      File.symlink("B", File.join(framework, "Versions", "Current"))

      error = assert_raises(ArgumentError) do
        Zui::MacOSBundleSeal.seal!(native, command: FakeCodesign.new)
      end
      assert_includes error.message, "unexpected macOS framework link"
    end
  end

  def test_reports_codesign_failures
    Dir.mktmpdir do |native|
      framework_fixture(native)

      error = assert_raises(ArgumentError) do
        Zui::MacOSBundleSeal.seal!(native, command: FakeCodesign.new(successful: false))
      end
      assert_includes error.message, "invalid framework"
    end
  end

  private

  def framework_fixture(native)
    application = File.join(native, "zui-host.app")
    executable = File.join(application, "Contents", "MacOS", "zui-host")
    framework = File.join(application, "Contents", "Frameworks", "QtCore.framework")
    resources = File.join(framework, "Versions", "A", "Resources")
    FileUtils.mkdir_p(resources)
    FileUtils.mkdir_p(File.dirname(executable))
    File.binwrite(executable, "host")
    File.binwrite(File.join(framework, "Versions", "A", "QtCore"), "framework")
    File.write(File.join(resources, "Info.plist"), "plist")
    framework
  end
end
