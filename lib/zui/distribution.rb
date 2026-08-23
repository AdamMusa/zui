# frozen_string_literal: true

require "fileutils"
require "json"

module Zui
  class Distribution
    attr_reader :platform

    def initialize(host: Host.new, platform: Platform.current, framework_root: FRAMEWORK_ROOT)
      @host = host
      @platform = platform.assert_supported!
      @framework_root = framework_root
    end

    def bundle(source, name: nil, destination: nil)
      project = File.expand_path(source)
      raise ArgumentError, "project directory not found: #{project}" unless File.directory?(project)
      raise ArgumentError, "main.rb not found: #{project}" unless File.file?(File.join(project, "main.rb"))
      app_name = name || titleize(File.basename(project))
      destination ||= default_destination(project, app_name)
      destination = File.expand_path(destination)
      raise ArgumentError, "bundle destination already exists: #{destination}" if File.exist?(destination)

      case platform.os
      when :linux then bundle_linux(project, destination, app_name)
      when :macos then bundle_macos(project, destination, app_name)
      when :windows then bundle_windows(project, destination, app_name)
      end
      destination
    rescue StandardError
      FileUtils.remove_entry(destination) if destination && File.exist?(destination)
      raise
    end

    private

    def bundle_linux(project, destination, app_name)
      FileUtils.mkdir_p([File.join(destination, "app"), File.join(destination, "bin"),
                         File.join(destination, "runtime"), File.join(destination, "share", "applications")])
      install_application(project, File.join(destination, "app"))
      install_runtime(File.join(destination, "runtime"))
      FileUtils.cp(@host.executable, File.join(destination, "bin", "zui-host"))
      FileUtils.chmod(0o755, File.join(destination, "bin", "zui-host"))
      write_linux_launcher(destination, app_name)
      desktop_name = "#{slug(app_name)}.desktop"
      File.write(File.join(destination, "share", "applications", desktop_name), <<~DESKTOP)
        [Desktop Entry]
        Type=Application
        Name=#{app_name}
        Exec=#{File.join(destination, "run")}
        Terminal=false
        Categories=Utility;
      DESKTOP
      write_manifest(destination, app_name)
    end

    def bundle_macos(project, destination, app_name)
      contents = File.join(destination, "Contents")
      macos = File.join(contents, "MacOS")
      resources = File.join(contents, "Resources")
      FileUtils.mkdir_p([macos, File.join(resources, "app"), File.join(resources, "runtime")])
      install_application(project, File.join(resources, "app"))
      install_runtime(File.join(resources, "runtime"))
      FileUtils.cp(@host.executable, File.join(macos, "zui-host"))
      FileUtils.chmod(0o755, File.join(macos, "zui-host"))
      File.write(File.join(macos, "run"), macos_launcher(app_name))
      FileUtils.chmod(0o755, File.join(macos, "run"))
      File.write(File.join(contents, "Info.plist"), info_plist(app_name))
      write_manifest(resources, app_name)
    end

    def bundle_windows(project, destination, app_name)
      FileUtils.mkdir_p([File.join(destination, "app"), File.join(destination, "bin"),
                         File.join(destination, "runtime")])
      install_application(project, File.join(destination, "app"))
      install_runtime(File.join(destination, "runtime"))
      FileUtils.cp(@host.executable, File.join(destination, "bin", "zui-host.exe"))
      File.write(File.join(destination, "run.rb"), windows_ruby_launcher(app_name))
      File.write(File.join(destination, "run.cmd"), windows_command_launcher)
      write_manifest(destination, app_name)
    end

    def install_application(source, destination)
      entries = Dir.children(source).reject do |entry|
        entry_path = File.join(source, entry)
        %w[.git dist].include?(entry) || destination.start_with?("#{entry_path}#{File::SEPARATOR}")
      end
      FileUtils.cp_r(entries.map { |entry| File.join(source, entry) }, destination) unless entries.empty?
    end

    def install_runtime(destination)
      Runtime.install_qml(File.join(destination, "qml"), framework_root: @framework_root)
      FileUtils.mkdir_p(File.join(destination, "lib"))
      FileUtils.cp(File.join(@framework_root, "lib", "zui.rb"), File.join(destination, "lib", "zui.rb"))
      FileUtils.cp_r(File.join(@framework_root, "lib", "zui"), File.join(destination, "lib", "zui"))
    end

    def write_linux_launcher(destination, app_name)
      File.write(File.join(destination, "run"), <<~SH)
        #!/bin/sh
        set -eu
        bundle_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
        ruby_command=${ZUI_RUBY:-ruby}
        exec "$bundle_dir/bin/zui-host" \
          --qml-root "$bundle_dir/runtime/qml" \
          --project "$bundle_dir/app" \
          --program "$bundle_dir/app/main.rb" \
          --ruby "$ruby_command" \
          --load-path "$bundle_dir/runtime/lib" \
          --name #{shell_quote(app_name)}
      SH
      FileUtils.chmod(0o755, File.join(destination, "run"))
    end

    def macos_launcher(app_name)
      <<~SH
        #!/bin/sh
        set -eu
        contents=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
        resources="$contents/Resources"
        ruby_command=${ZUI_RUBY:-ruby}
        exec "$contents/MacOS/zui-host" \
          --qml-root "$resources/runtime/qml" \
          --project "$resources/app" \
          --program "$resources/app/main.rb" \
          --ruby "$ruby_command" \
          --load-path "$resources/runtime/lib" \
          --name #{shell_quote(app_name)}
      SH
    end

    def windows_ruby_launcher(app_name)
      <<~RUBY
        # frozen_string_literal: true

        require "rbconfig"

        bundle_dir = File.expand_path(__dir__)
        arguments = [
          File.join(bundle_dir, "bin", "zui-host.exe"),
          "--qml-root", File.join(bundle_dir, "runtime", "qml"),
          "--project", File.join(bundle_dir, "app"),
          "--program", File.join(bundle_dir, "app", "main.rb"),
          "--ruby", RbConfig.ruby,
          "--load-path", File.join(bundle_dir, "runtime", "lib"),
          "--name", #{app_name.to_s.dump}
        ]
        exec(*arguments)
      RUBY
    end

    def windows_command_launcher
      <<~CMD.gsub("\n", "\r\n")
        @echo off
        setlocal
        if defined ZUI_RUBY (
          "%ZUI_RUBY%" "%~dp0run.rb"
        ) else (
          ruby "%~dp0run.rb"
        )
        exit /b %ERRORLEVEL%
      CMD
    end

    def info_plist(app_name)
      identifier = "dev.zui.#{slug(app_name).tr("-", ".")}"
      <<~PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>CFBundleExecutable</key><string>run</string>
          <key>CFBundleIdentifier</key><string>#{identifier}</string>
          <key>CFBundleName</key><string>#{xml_escape(app_name)}</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>CFBundleShortVersionString</key><string>#{VERSION}</string>
          <key>NSHighResolutionCapable</key><true/>
        </dict></plist>
      PLIST
    end

    def write_manifest(directory, app_name)
      File.write(File.join(directory, "zui-bundle.json"), JSON.pretty_generate(
        "format" => 1, "framework" => "zui", "version" => VERSION,
        "platform" => platform.os.to_s, "architecture" => platform.arch.to_s,
        "name" => app_name
      ))
    end

    def default_destination(project, app_name)
      base = File.join(project, "dist")
      platform.macos? ? File.join(base, "#{app_name}.app") : File.join(base, "#{slug(app_name)}-#{platform.id}")
    end

    def titleize(value) = value.split(/[-_]/).map(&:capitalize).join(" ")
    def slug(value) = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    def shell_quote(value) = "'#{value.to_s.gsub("'", %q('"'"'))}'"
    def xml_escape(value) = value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end
end
