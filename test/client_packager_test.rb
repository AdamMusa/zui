# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "../lib/zui/client_packager"

class ClientPackagerTest < Minitest::Test
  def test_client_archive_is_reproducible
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      source = File.join(directory, "stage")
      FileUtils.mkdir_p([
        File.join(source, "bin"), File.join(source, "lib"), File.join(source, "plugins"),
        File.join(source, "qml")
      ])
      File.write(File.join(source, "bin", "zui-host"), "host")
      FileUtils.chmod(0o755, File.join(source, "bin", "zui-host"))
      File.write(File.join(source, "lib", "libQt6Core.so.6"), "qt")
      first = Zui::ClientPackager.new(platform:, source_date_epoch: 1_234_567_890).package(
        source:, output: File.join(directory, "first"), executable: "bin/zui-host"
      )
      File.utime(Time.now, Time.now, File.join(source, "bin", "zui-host"))
      second = Zui::ClientPackager.new(platform:, source_date_epoch: 1_234_567_890).package(
        source:, output: File.join(directory, "second"), executable: "bin/zui-host"
      )

      assert_equal File.binread(first), File.binread(second)
      assert_equal File.read("#{first}.sha256").split.first, File.read("#{second}.sha256").split.first
    end
  end

  def test_does_not_duplicate_payload_referenced_by_framework_symlinks
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      source = File.join(directory, "stage")
      FileUtils.mkdir_p([
        File.join(source, "bin"), File.join(source, "lib"), File.join(source, "plugins"),
        File.join(source, "qml"), File.join(source, "Framework.framework", "Versions", "A")
      ])
      File.write(File.join(source, "bin", "zui-host"), "host")
      FileUtils.chmod(0o755, File.join(source, "bin", "zui-host"))
      File.write(File.join(source, "lib", "libQt6Core.so.6"), "qt")
      canonical = File.join(source, "Framework.framework", "Versions", "A", "Framework")
      File.write(canonical, "canonical framework binary")
      File.symlink(File.join("Versions", "A", "Framework"),
                   File.join(source, "Framework.framework", "Framework"))
      File.symlink("A", File.join(source, "Framework.framework", "Versions", "Current"))

      archive = Zui::ClientPackager.new(platform:).package(
        source:, output: File.join(directory, "output"), executable: "bin/zui-host"
      )

      entries = archive_entries(archive)
      assert_includes entries, "Framework.framework/Versions/A/Framework"
      refute_includes entries, "Framework.framework/Framework"
      refute entries.any? { |entry| entry.start_with?("Framework.framework/Versions/Current") }
    end
  end

  def test_packages_only_native_payload_and_round_trips_through_configure
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      source = File.join(directory, "stage")
      FileUtils.mkdir_p([
        File.join(source, "bin"), File.join(source, "lib"), File.join(source, "plugins"),
        File.join(source, "qml")
      ])
      File.write(File.join(source, "bin", "zui-host"), "host")
      FileUtils.chmod(0o755, File.join(source, "bin", "zui-host"))
      File.write(File.join(source, "lib", "libQt6Core.so.6"), "qt")
      File.write(File.join(source, "qml", "qmldir"), "module QtQuick")
      output = File.join(directory, "output")

      archive = Zui::ClientPackager.new(platform:).package(
        source:, output:, executable: "bin/zui-host", qt_version: "6.8.3"
      )
      client = Zui::Client.new(platform:, cache_root: File.join(directory, "cache"), environment: {
        "ZUI_CLIENT_ARCHIVE" => archive,
        "ZUI_CLIENT_CHECKSUM" => "#{archive}.sha256"
      })

      client.configure!
      assert client.configured?
      assert_equal "6.8.3", client.manifest.fetch("qt_version")
      assert File.file?(File.join(client.root, "lib", "libQt6Core.so.6"))
      refute File.exist?(File.join(client.root, "app"))
      refute File.exist?(File.join(client.root, "lib", "zui.rb"))
    end
  end

  def test_rejects_framework_payload_in_a_native_client
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      FileUtils.mkdir_p([File.join(directory, "bin"), File.join(directory, "lib")])
      File.write(File.join(directory, "bin", "zui-host"), "host")
      FileUtils.chmod(0o755, File.join(directory, "bin", "zui-host"))
      File.write(File.join(directory, "lib", "zui.rb"), "framework")

      error = assert_raises(ArgumentError) do
        Zui::ClientPackager.new(platform:).package(
          source: directory, output: File.join(directory, "out"), executable: "bin/zui-host"
        )
      end
      assert_includes error.message, "framework payload"
    end
  end

  def test_windows_client_layout_round_trips_without_framework_source
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :windows, arch: :x86_64)
      source = File.join(directory, "stage")
      FileUtils.mkdir_p([File.join(source, "bin"), File.join(source, "plugins"), File.join(source, "qml")])
      File.write(File.join(source, "bin", "zui-host.exe"), "host")
      File.write(File.join(source, "bin", "Qt6Core.dll"), "qt")

      archive = Zui::ClientPackager.new(platform:).package(
        source:, output: File.join(directory, "output"), executable: "bin/zui-host.exe"
      )
      client = install_packaged_client(platform, directory, archive)

      assert client.configured?
      assert_equal "bin/zui-host.exe", client.executable_relative_path
      assert_equal ["bin"], client.environment_entries.fetch("PATH")
      refute File.exist?(File.join(client.root, "app"))
    end
  end

  def test_macos_client_layout_round_trips_as_a_nested_native_app
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :macos, arch: :arm64)
      source = File.join(directory, "stage")
      app = File.join(source, "zui-host.app", "Contents")
      FileUtils.mkdir_p([
        File.join(app, "MacOS"), File.join(app, "Frameworks"), File.join(app, "PlugIns"),
        File.join(app, "Resources", "qml")
      ])
      executable = File.join(app, "MacOS", "zui-host")
      File.write(executable, "host")
      FileUtils.chmod(0o755, executable)

      archive = Zui::ClientPackager.new(platform:).package(
        source:, output: File.join(directory, "output"),
        executable: "zui-host.app/Contents/MacOS/zui-host"
      )
      client = install_packaged_client(platform, directory, archive)

      assert client.configured?
      assert_equal "zui-host.app/Contents/MacOS/zui-host", client.executable_relative_path
      assert_equal ["zui-host.app/Contents/PlugIns"], client.environment_entries.fetch("QT_PLUGIN_PATH")
      assert_equal ["zui-host.app/Contents/Resources/qml"], client.environment_entries.fetch("QML_IMPORT_PATH")
      assert_equal ["zui-host.app/Contents/Resources/qml"], client.environment_entries.fetch("QML2_IMPORT_PATH")
      refute File.exist?(File.join(client.root, "app"))
    end
  end

  private

  def install_packaged_client(platform, directory, archive)
    client = Zui::Client.new(platform:, cache_root: File.join(directory, "cache"), environment: {
      "ZUI_CLIENT_ARCHIVE" => archive,
      "ZUI_CLIENT_CHECKSUM" => "#{archive}.sha256"
    })
    client.configure!
    client
  end

  def archive_entries(archive)
    entries = []
    Zlib::GzipReader.open(archive) do |gzip|
      Gem::Package::TarReader.new(gzip) do |tar|
        tar.each { |entry| entries << entry.full_name }
      end
    end
    entries
  end
end
