# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/client_fixture"

class HostTest < Minitest::Test
  def test_requires_explicit_configuration_instead_of_building_from_source
    client = Object.new
    client.define_singleton_method(:configured?) { false }
    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    host = Zui::Host.new(platform:, client:, environment: {})

    error = assert_raises(ArgumentError) { host.executable }
    assert_includes error.message, "zui configure"
    refute host.available?
  end

  def test_uses_the_configured_clients_executable_and_environment
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      root = ClientFixture.create(File.join(directory, "client"), platform:)
      client = Zui::Client.new(platform:, environment: { "ZUI_CLIENT_ROOT" => root })
      host = Zui::Host.new(platform:, client:, environment: {})

      assert_equal File.join(root, "bin", "zui-host"), host.executable
      assert_equal File.join(root, "qml"), host.environment.fetch("QML_IMPORT_PATH")
    end
  end

  def test_explicit_host_override_does_not_inherit_client_paths
    Dir.mktmpdir do |directory|
      executable = File.join(directory, "custom-host")
      File.write(executable, "host")
      FileUtils.chmod(0o755, executable)
      client = Object.new
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      host = Zui::Host.new(platform:, client:, environment: { "ZUI_HOST" => executable })

      assert_equal executable, host.executable
      assert_equal({ "PATH" => "/bin" }, host.environment("PATH" => "/bin"))
    end
  end
end
