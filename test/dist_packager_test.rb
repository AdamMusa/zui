# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/client_fixture"

class DistPackagerTest < Minitest::Test
  FakeRuntimeBuilder = Struct.new(:platform) do
    def install(project:, destination:)
      executable = platform.windows? ? "bin/ruby.exe" : "bin/ruby"
      FileUtils.mkdir_p(File.join(destination, "bin"))
      File.write(File.join(destination, executable), "runtime-fixture")
      FileUtils.chmod(0o755, File.join(destination, executable)) unless platform.windows?
      Zui::ApplicationRuntime.new(engine: "cruby", version: "3.3.0", executable:).write(destination)
    end
  end

  def test_linux_dist_produces_deb_and_rpm_artifacts
    skip "POSIX packaging fixture" if Gem.win_platform?

    with_project(Zui::Platform.new(os: :linux, arch: :x86_64)) do |project, client, tools|
      write_tool(tools, "rpmbuild", <<~SH)
        #!/bin/sh
        topdir=""
        while [ "$#" -gt 0 ]; do
          if [ "$1" = "--define" ]; then
            shift
            topdir=${1#_topdir }
          fi
          shift
        done
        mkdir -p "$topdir/RPMS/x86_64"
        printf 'rpm-fixture' > "$topdir/RPMS/x86_64/signal-board.rpm"
      SH
      output = File.join(project, "releases")
      packager = Zui::DistPackager.new(client:, platform: client.platform,
                                       environment: { "PATH" => tools })

      artifacts = packager.package(project, output:)

      assert_equal %w[.deb .rpm], artifacts.map { |path| File.extname(path) }
      assert artifacts.all? { |path| File.file?(path) }
      assert_equal "!<arch>\n", File.binread(artifacts.first, 8)
      members = ar_members(artifacts.first)
      assert_includes members, "control.tar.gz"
      assert_includes members, "data.tar.gz"
      control_entries = tar_gzip_entries(members.fetch("control.tar.gz"))
      data_entries = tar_gzip_entries(members.fetch("data.tar.gz"))
      assert_includes control_entries.keys, "./control"
      assert_includes control_entries.fetch("./control"), "Package: signal-board"
      assert_includes data_entries.keys, "./opt/signal-board/run"
      assert_includes data_entries.keys, "./usr/share/applications/signal-board.desktop"
      assert_includes data_entries.keys, "./usr/share/icons/hicolor/256x256/apps/signal-board.png"
      assert_equal "rpm-fixture", File.read(artifacts.last)
      assert packager.tree_shake_report
    end
  end

  def test_macos_dist_produces_a_dmg_and_embeds_release_metadata
    skip "POSIX packaging fixture" if Gem.win_platform?

    with_project(Zui::Platform.new(os: :macos, arch: :arm64)) do |project, client, tools|
      write_tool(tools, "hdiutil", <<~SH)
        #!/bin/sh
        source=""
        output=""
        previous=""
        for argument in "$@"; do
          [ "$previous" = "-srcfolder" ] && source=$argument
          previous=$argument
          output=$argument
        done
        test -f "$source/Signal Board.app/Contents/Resources/Application.icns" || exit 20
        grep -q 'com.example.signal-board' "$source/Signal Board.app/Contents/Info.plist" || exit 21
        grep -q '<string>1.2.3</string>' "$source/Signal Board.app/Contents/Info.plist" || exit 22
        printf 'dmg-fixture' > "$output"
      SH
      packager = Zui::DistPackager.new(client:, platform: client.platform,
                                       environment: { "PATH" => tools })

      artifacts = packager.package(project, output: File.join(project, "releases"))

      assert_equal 1, artifacts.length
      assert_match(/macos-arm64\.dmg\z/, artifacts.first)
      assert_equal "dmg-fixture", File.read(artifacts.first)
    end
  end

  def test_windows_dist_produces_an_inno_setup_executable
    skip "POSIX packaging fixture" if Gem.win_platform?

    with_project(Zui::Platform.new(os: :windows, arch: :x86_64)) do |project, client, tools|
      write_tool(tools, "iscc", <<~'SH')
        #!/bin/sh
        script=$1
        output=$(sed -n 's/^OutputDir=//p' "$script")
        base=$(sed -n 's/^OutputBaseFilename=//p' "$script")
        source_glob=$(sed -n 's/^Source: "\(.*\)";.*/\1/p' "$script")
        source=${source_glob%/*}
        [ "$source" = "$source_glob" ] && source=${source_glob%\\*}
        test -f "$source/app.ico" || exit 20
        grep -q '^AppId=com.example.signal-board$' "$script" || exit 21
        mkdir -p "$output"
        printf 'setup-fixture' > "$output/$base.exe"
      SH
      packager = Zui::DistPackager.new(client:, platform: client.platform,
                                       environment: { "PATH" => tools })

      artifacts = packager.package(project, output: File.join(project, "releases"))

      assert_equal 1, artifacts.length
      assert_match(/windows-x86_64-setup\.exe\z/, artifacts.first)
      assert_equal "setup-fixture", File.read(artifacts.first)
    end
  end

  def test_dist_fails_before_bundling_when_the_platform_tool_is_missing
    with_project(Zui::Platform.new(os: :linux, arch: :x86_64)) do |project, client, _tools|
      packager = Zui::DistPackager.new(client:, platform: client.platform,
                                       environment: { "PATH" => "" })

      error = assert_raises(ArgumentError) do
        packager.package(project, output: File.join(project, "releases"))
      end

      assert_includes error.message, "rpmbuild"
      refute File.exist?(File.join(project, "releases"))
    end
  end

  def test_full_linux_packages_do_not_depend_on_system_ruby
    skip "POSIX packaging fixture" if Gem.win_platform?

    platform = Zui::Platform.new(os: :linux, arch: :x86_64)
    with_project(platform) do |project, client, tools|
      write_tool(tools, "rpmbuild", <<~SH)
        #!/bin/sh
        topdir=""
        while [ "$#" -gt 0 ]; do
          if [ "$1" = "--define" ]; then
            shift
            topdir=${1#_topdir }
          fi
          shift
        done
        mkdir -p "$topdir/RPMS/x86_64"
        cp "$topdir/SPECS/signal-board.spec" "$topdir/RPMS/x86_64/signal-board.rpm"
      SH
      packager = Zui::DistPackager.new(
        client:, platform:, environment: { "PATH" => tools }, runtime_mode: :full,
        runtime_builder: FakeRuntimeBuilder.new(platform)
      )

      deb, rpm = packager.package(project, output: File.join(project, "releases"))
      control = tar_gzip_entries(ar_members(deb).fetch("control.tar.gz")).fetch("./control")

      refute_includes control, "Depends: ruby"
      refute_includes File.read(rpm), "Requires: ruby"
    end
  end

  private

  def with_project(platform)
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      tools = File.join(directory, "tools")
      FileUtils.mkdir_p([project, tools, File.join(project, "assets")])
      File.write(File.join(project, "main.rb"), "require 'zui'\nZui.app { app { text 'release' } }\n")
      File.binwrite(File.join(project, "assets", "icon.png"), "\x89PNG\r\n\x1a\n".b)
      File.binwrite(File.join(project, "assets", "icon.icns"), "icnsfixture")
      File.binwrite(File.join(project, "assets", "icon.ico"), "\x00\x00\x01\x00fixture".b)
      File.write(File.join(project, Zui::Dist::CONFIG_FILE), <<~RUBY)
        Zui::Dist.configure do
          name "Signal Board"
          identifier "com.example.signal-board"
          version "1.2.3"
          publisher "Example Company <dev@example.com>"
          description "A native signal dashboard."
          license "MIT"
          homepage "https://example.com/signal-board"
          icon linux: "assets/icon.png", macos: "assets/icon.icns", windows: "assets/icon.ico"
          categories "Utility"
        end
      RUBY
      client_root = ClientFixture.create(File.join(directory, "client"), platform:)
      client = Zui::Client.new(platform:, environment: { "ZUI_CLIENT_ROOT" => client_root })
      yield project, client, tools
    end
  end

  def write_tool(directory, name, contents)
    path = File.join(directory, name)
    File.write(path, contents)
    FileUtils.chmod(0o755, path)
  end

  def ar_members(path)
    data = File.binread(path)
    offset = 8
    members = {}
    while offset + 60 <= data.bytesize
      header = data.byteslice(offset, 60)
      name = header.byteslice(0, 16).strip.delete_suffix("/")
      size = Integer(header.byteslice(48, 10).strip)
      members[name] = data.byteslice(offset + 60, size)
      offset += 60 + size
      offset += 1 if size.odd?
    end
    members
  end

  def tar_gzip_entries(data)
    entries = {}
    gzip = Zlib::GzipReader.new(StringIO.new(data))
    Gem::Package::TarReader.new(gzip) do |tar|
      tar.each { |entry| entries[entry.full_name] = entry.file? ? entry.read : nil }
    end
    entries
  ensure
    gzip&.close
  end
end
