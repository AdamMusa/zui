# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/client_fixture"

class DistPackagerTest < Minitest::Test
  FakeRuntimeBuilder = Struct.new(:platform, :engine) do
    def initialize(platform, engine = "mruby") = super

    def install(project:, destination:)
      name = engine == "mruby" ? "mruby" : "ruby"
      name = "#{name}.exe" if platform.windows?
      executable = "bin/#{name}"
      FileUtils.mkdir_p(File.join(destination, "bin"))
      File.write(File.join(destination, executable), "runtime-fixture")
      FileUtils.chmod(0o755, File.join(destination, executable)) unless platform.windows?
      File.write(File.join(destination, "app.rb"), "# lite fixture\n") if engine == "mruby"
      Zui::ApplicationRuntime.new(
        engine:, version: engine == "mruby" ? "4.0.0" : "3.3.0", executable:,
        program: engine == "mruby" ? "app.rb" : nil,
        load_path: engine == "mruby" ? "" : nil
      ).write(destination)
    end
  end

  def test_linux_dist_produces_deb_and_rpm_artifacts
    skip "POSIX packaging fixture" if Gem.win_platform?

    with_project(Zui::Platform.new(os: :linux, arch: :x86_64)) do |project, client, tools|
      write_tool(tools, "rpmbuild", <<~SH)
        #!/bin/sh
        test "$SOURCE_DATE_EPOCH" = "946684800" || exit 30
        case " $* " in *" _buildhost reproducible "*) ;; *) exit 31 ;; esac
        case " $* " in *" _buildtime 946684800 "*) ;; *) exit 32 ;; esac
        case " $* " in *" build_mtime_policy clamp_to_source_date_epoch "*) ;; *) exit 33 ;; esac
        topdir=""
        while [ "$#" -gt 0 ]; do
          if [ "$1" = "--define" ]; then
            shift
            case "$1" in
              "_topdir "*) topdir=${1#_topdir } ;;
            esac
          fi
          shift
        done
        mkdir -p "$topdir/RPMS/x86_64"
        printf 'rpm-fixture' > "$topdir/RPMS/x86_64/signal-board.rpm"
      SH
      output = File.join(project, "releases")
      packager = lite_packager(client:, tools:)

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
      refute_includes control_entries.fetch("./control"), "Depends: ruby"
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
        command=$1
        shift
        if [ "$command" = "makehybrid" ]; then
          output=""
          previous=""
          for argument in "$@"; do
            [ "$previous" = "-o" ] && output=$argument
            previous=$argument
            source=$argument
          done
          test -f "$source/Signal Board.app/Contents/Resources/Application.icns" || exit 20
          grep -q 'com.example.signal-board' "$source/Signal Board.app/Contents/Info.plist" || exit 21
          grep -q '<string>1.2.3</string>' "$source/Signal Board.app/Contents/Info.plist" || exit 22
          printf 'hybrid-fixture' > "$output"
        elif [ "$command" = "convert" ]; then
          source=$1
          output=""
          previous=""
          for argument in "$@"; do
            [ "$previous" = "-o" ] && output=$argument
            previous=$argument
          done
          test -f "$source" || exit 23
          /bin/dd if=/dev/zero of="$output" bs=512 count=1 2>/dev/null
          printf 'koly' | /bin/dd of="$output" bs=1 seek=0 conv=notrunc 2>/dev/null
          printf 'random-segmentid' | /bin/dd of="$output" bs=1 seek=64 conv=notrunc 2>/dev/null
        else
          exit 24
        fi
      SH
      packager = lite_packager(client:, tools:)

      artifacts = packager.package(project, output: File.join(project, "releases"))

      assert_equal 1, artifacts.length
      assert_match(/macos-arm64\.dmg\z/, artifacts.first)
      assert_equal "koly", File.binread(artifacts.first, 4)
      assert_equal "\0" * 16, File.binread(artifacts.first, 16, 64)
    end
  end

  def test_windows_dist_produces_an_inno_setup_executable
    skip "POSIX packaging fixture" if Gem.win_platform?

    with_project(Zui::Platform.new(os: :windows, arch: :x86_64)) do |project, client, tools|
      write_tool(tools, "iscc", <<~'SH')
        #!/bin/sh
        [ "$1" = "--no-ide-signtools" ] || exit 30
        [ "$2" = "--no-signing" ] || exit 31
        for script do :; done
        output=$(sed -n 's/^OutputDir=//p' "$script")
        base=$(sed -n 's/^OutputBaseFilename=//p' "$script")
        source=$(sed -n 's/^Source: "\(.*app.ico\)";.*/\1/p' "$script")
        test -f "$source" || exit 20
        grep -q '^AppId=com.example.signal-board$' "$script" || exit 21
        grep -q '^CompressionThreads=1$' "$script" || exit 22
        grep -q '^LZMANumBlockThreads=1$' "$script" || exit 23
        grep -q '^TimeStampsInUTC=yes$' "$script" || exit 24
        grep -q '^TimeStampRounding=1$' "$script" || exit 25
        ! grep -q 'recursesubdirs' "$script" || exit 26
        mkdir -p "$output"
        printf 'setup-fixture' > "$output/$base.exe"
      SH
      packager = lite_packager(client:, tools:)

      artifacts = packager.package(project, output: File.join(project, "releases"))

      assert_equal 1, artifacts.length
      assert_match(/windows-x86_64-setup\.exe\z/, artifacts.first)
      assert_equal "setup-fixture", File.read(artifacts.first)
    end
  end

  def test_dist_fails_before_bundling_when_the_platform_tool_is_missing
    with_project(Zui::Platform.new(os: :linux, arch: :x86_64)) do |project, client, _tools|
      packager = Zui::DistPackager.new(
        client:, platform: client.platform, environment: { "PATH" => "" },
        runtime_builder: FakeRuntimeBuilder.new(client.platform)
      )

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
            case "$1" in
              "_topdir "*) topdir=${1#_topdir } ;;
            esac
          fi
          shift
        done
        mkdir -p "$topdir/RPMS/x86_64"
        cp "$topdir/SPECS/signal-board.spec" "$topdir/RPMS/x86_64/signal-board.rpm"
      SH
      packager = Zui::DistPackager.new(
        client:, platform:, environment: { "PATH" => tools }, runtime_mode: :full,
        runtime_builder: FakeRuntimeBuilder.new(platform, "cruby")
      )

      deb, rpm = packager.package(project, output: File.join(project, "releases"))
      control = tar_gzip_entries(ar_members(deb).fetch("control.tar.gz")).fetch("./control")

      refute_includes control, "Depends: ruby"
      refute_includes File.read(rpm), "Requires: ruby"
    end
  end

  private

  def lite_packager(client:, tools:)
    Zui::DistPackager.new(
      client:, platform: client.platform, environment: { "PATH" => tools },
      runtime_builder: FakeRuntimeBuilder.new(client.platform)
    )
  end

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
