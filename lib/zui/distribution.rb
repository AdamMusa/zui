# frozen_string_literal: true

require "fileutils"
require "json"
require "rbconfig"

module Zui
  class Distribution
    RUNTIME_MODES = %i[lite full].freeze
    DESKTOP_APPLICATION_EXCLUDES = %w[
      .bundle .cache .git .github .idea .ruby-lsp .vscode android build coverage dist ios log
      node_modules pkg spec test tmp
    ].freeze
    DESKTOP_APPLICATION_FILES = %w[
      .DS_Store .gitattributes .gitignore Gemfile Gemfile.lock README.md Rakefile config.rb
    ].freeze
    DESKTOP_APPLICATION_PATHS = %w[vendor/bundle vendor/cache].freeze

    attr_reader :platform, :tree_shake_report, :runtime_tree_shake_report, :runtime_mode

    def initialize(client: nil, platform: Platform.current, framework_root: FRAMEWORK_ROOT,
                   ruby: RbConfig.ruby, tree_shake: true, release_config: nil, runtime_mode: :lite,
                   runtime_builder: nil, gem_spec_loader: nil, source_date_epoch: nil)
      @platform = platform.assert_supported!
      @client = client || Client.new(platform: @platform)
      @framework_root = framework_root
      @ruby = File.expand_path(ruby)
      @tree_shake = tree_shake == true
      @runtime_mode = runtime_mode.to_sym
      unless RUNTIME_MODES.include?(@runtime_mode)
        raise ArgumentError, "unsupported application runtime: #{runtime_mode}"
      end
      @tree_shake_report = nil
      @runtime_tree_shake_report = nil
      @release_config = release_config
      @runtime_builder = runtime_builder
      @gem_spec_loader = gem_spec_loader
      @application_runtime = nil
      @locked_gem_specs = nil
      @bundled_project_gem_paths = []
      @source_date_epoch = ReproducibleBuild.epoch(source_date_epoch)
      @bundle_config = nil
      @release_asset_paths = []
    end

    def bundle(source, name: nil, destination: nil)
      created = false
      project = File.expand_path(source)
      @project = project
      raise ArgumentError, "project directory not found: #{project}" unless File.directory?(project)
      raise ArgumentError, "main.rb not found: #{project}" unless File.file?(File.join(project, "main.rb"))
      unless @client.configured?
        raise ArgumentError, "Zui is not configured for #{platform.id}; run `zui doctor --fix` before bundling"
      end
      @bundle_config = @release_config || load_project_config(project)
      @qt_configuration = QtBundleConfiguration.load(project)
      @release_asset_paths = configured_release_assets(project)
      prepare_locked_gems(project)
      app_name = name || titleize(File.basename(project))
      destination ||= default_destination(project, app_name)
      destination = File.expand_path(destination)
      raise ArgumentError, "bundle destination already exists: #{destination}" if File.exist?(destination)
      created = true

      case platform.os
      when :linux then bundle_linux(project, destination, app_name)
      when :macos then bundle_macos(project, destination, app_name)
      when :windows then bundle_windows(project, destination, app_name)
      end
      finalize_reproducible_bundle(destination)
      destination
    rescue StandardError
      FileUtils.remove_entry(destination) if created && destination && File.exist?(destination)
      raise
    end

    private

    def bundle_linux(project, destination, app_name)
      FileUtils.mkdir_p([File.join(destination, "app"),
                         File.join(destination, "runtime"), File.join(destination, "share", "applications")])
      install_application(project, File.join(destination, "app"))
      install_runtime(File.join(destination, "runtime"))
      install_application_runtime(project, File.join(destination, "runtime"))
      @client.copy_to(File.join(destination, "runtime", "native"))
      shake_bundle(project, File.join(destination, "runtime"))
      write_linux_launcher(destination, app_name)
      desktop_name = "#{slug(app_name)}.desktop"
      File.write(File.join(destination, "share", "applications", desktop_name), <<~DESKTOP)
        [Desktop Entry]
        Type=Application
        Name=#{app_name}
        Exec=./run
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
      install_application_runtime(project, File.join(resources, "runtime"))
      native = File.join(resources, "runtime", "native")
      @client.copy_to(native)
      MacOSQmlPayload.deduplicate!(native)
      shake_bundle(project, File.join(resources, "runtime"))
      MacOSArchitecture.thin!(native, architecture: platform.arch)
      MacOSBundleSeal.seal!(native)
      icon_name = install_macos_release_icon(resources)
      File.write(File.join(macos, "run"), macos_launcher(app_name))
      FileUtils.chmod(0o755, File.join(macos, "run"))
      File.write(File.join(contents, "Info.plist"), info_plist(app_name, icon_name:))
      write_manifest(resources, app_name)
    end

    def bundle_windows(project, destination, app_name)
      FileUtils.mkdir_p([File.join(destination, "app"),
                         File.join(destination, "runtime")])
      install_application(project, File.join(destination, "app"))
      install_runtime(File.join(destination, "runtime"))
      install_application_runtime(project, File.join(destination, "runtime"))
      @client.copy_to(File.join(destination, "runtime", "native"))
      shake_bundle(project, File.join(destination, "runtime"))
      install_windows_release_icon(destination)
      if @application_runtime
        File.write(File.join(destination, "run.cmd"), windows_private_runtime_launcher(app_name))
      else
        File.write(File.join(destination, "run.rb"), windows_ruby_launcher(app_name))
        File.write(File.join(destination, "run.cmd"), windows_command_launcher)
      end
      write_manifest(destination, app_name)
    end

    def install_application(source, destination)
      FileUtils.mkdir_p(destination)
      copy_desktop_application(source, destination, source, destination)
    end

    def copy_desktop_application(source, destination, project, bundle)
      Dir.children(source).sort.each do |entry|
        source_path = File.join(source, entry)
        relative = source_path.delete_prefix("#{project}#{File::SEPARATOR}")
        next if desktop_application_excluded?(relative)
        next if bundle == source_path || bundle.start_with?("#{source_path}#{File::SEPARATOR}")

        destination_path = File.join(destination, entry)
        if File.symlink?(source_path)
          resolved = File.realpath(source_path)
          unless resolved == project || resolved.start_with?("#{project}#{File::SEPARATOR}")
            raise ArgumentError, "application symlink escapes the project: #{relative}"
          end
          File.symlink(File.readlink(source_path), destination_path)
        elsif File.directory?(source_path)
          FileUtils.mkdir_p(destination_path)
          copy_desktop_application(source_path, destination_path, project, bundle)
          Dir.rmdir(destination_path) if Dir.empty?(destination_path)
        elsif File.file?(source_path)
          FileUtils.cp(source_path, destination_path)
        else
          raise ArgumentError, "unsupported application file: #{relative}"
        end
      end
    end

    def desktop_application_excluded?(relative)
      parts = relative.split(File::SEPARATOR)
      return true if parts.include?(".DS_Store")
      normalized = relative.tr(File::SEPARATOR, "/")
      return true if @release_asset_paths.include?(normalized)
      return true if DESKTOP_APPLICATION_PATHS.any? do |path|
        normalized == path || normalized.start_with?("#{path}/")
      end
      return true if @bundled_project_gem_paths.any? do |path|
        normalized == path || normalized.start_with?("#{path}/")
      end
      return false unless parts.length == 1

      DESKTOP_APPLICATION_EXCLUDES.include?(parts.first) ||
        parts.first.start_with?("cmake-build-") || DESKTOP_APPLICATION_FILES.include?(parts.first) ||
        parts.first.end_with?(".gemspec")
    end

    def install_runtime(destination)
      Runtime.install_qml(File.join(destination, "qml"), framework_root: @framework_root)
      return if runtime_mode == :full

      FileUtils.mkdir_p(File.join(destination, "lib"))
      FileUtils.cp(File.join(@framework_root, "lib", "zui.rb"), File.join(destination, "lib", "zui.rb"))
      source = File.join(@framework_root, "lib", "zui")
      target = File.join(destination, "lib", "zui")
      FileUtils.mkdir_p(target)
      entries = Dir.children(source).reject { |entry| %w[client_builder.rb client_packager.rb].include?(entry) }
      FileUtils.cp_r(entries.map { |entry| File.join(source, entry) }, target) unless entries.empty?
    end

    def install_application_runtime(project, destination)
      builder = @runtime_builder || if runtime_mode == :full
                                      options = { platform:, ruby: @ruby, tree_shake: @tree_shake }
                                      if @locked_gem_specs
                                        options[:spec_loader] = ->(_project) { @locked_gem_specs }
                                      end
                                      FullRuntime.new(**options)
                                    else
                                      LiteRuntime.new(platform:)
                                    end
      @application_runtime = builder.install(project:, destination: File.join(destination, "ruby"))
      @runtime_tree_shake_report = builder.tree_shake_report if builder.respond_to?(:tree_shake_report)
    end

    def prepare_locked_gems(project)
      return unless runtime_mode == :full

      loader = @gem_spec_loader
      loader ||= LockedGems.new.method(:specs) unless @runtime_builder
      return unless loader

      @locked_gem_specs = loader.call(project)
      @bundled_project_gem_paths = @locked_gem_specs.filter_map do |spec|
        next if spec.default_gem?

        root = File.expand_path(spec.full_gem_path)
        next if root == project || !root.start_with?("#{project}#{File::SEPARATOR}")

        root.delete_prefix("#{project}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
      end.uniq.sort
    end

    def write_linux_launcher(destination, app_name)
      File.write(File.join(destination, "run"), <<~SH)
        #!/bin/sh
        set -eu
        bundle_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
        native_dir="$bundle_dir/runtime/native"
        export ZUI_QT_STYLE=#{shell_quote(@qt_configuration.style)}
        #{posix_client_environment}
        #{posix_ruby_command}
        exec "$native_dir/#{@client.executable_relative_path}" \
          --qml-root "$bundle_dir/runtime/qml" \
          --project "$bundle_dir/app" \
          --program #{posix_program("$bundle_dir")} \
          --ruby "$ruby_command" \
          --load-path #{posix_load_path("$bundle_dir")} \
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
        native_dir="$resources/runtime/native"
        export ZUI_QT_STYLE=#{shell_quote(@qt_configuration.style)}
        #{posix_client_environment}
        #{posix_ruby_command}
        exec "$native_dir/#{@client.executable_relative_path}" \
          --qml-root "$resources/runtime/qml" \
          --project "$resources/app" \
          --program #{posix_program("$resources")} \
          --ruby "$ruby_command" \
          --load-path #{posix_load_path("$resources")} \
          --name #{shell_quote(app_name)}
      SH
    end

    def windows_ruby_launcher(app_name)
      <<~RUBY
        # frozen_string_literal: true

        require "rbconfig"

        bundle_dir = File.expand_path(__dir__)
        native_dir = File.join(bundle_dir, "runtime", "native")
        environment = { "ZUI_QT_STYLE" => #{@qt_configuration.style.dump} }
        #{windows_environment_builder}
        arguments = [
          File.join(native_dir, #{@client.executable_relative_path.dump}),
          "--qml-root", File.join(bundle_dir, "runtime", "qml"),
          "--project", File.join(bundle_dir, "app"),
          "--program", File.join(bundle_dir, "app", "main.rb"),
          "--ruby", RbConfig.ruby,
          "--load-path", File.join(bundle_dir, "runtime", "lib"),
          "--name", #{app_name.to_s.dump}
        ]
        exec(environment, *arguments)
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

    def windows_private_runtime_launcher(app_name)
      executable = @application_runtime.executable.tr("/", "\\")
      host = @client.executable_relative_path.tr("/", "\\")
      environment = @application_runtime.environment.map do |name, paths|
        value = paths.map { |path| "%ruby_root%\\#{path.tr('/', '\\')}" }.join(";")
        if name == "PATH"
          %(set "PATH=#{value};%PATH%")
        else
          %(set "#{name}=#{value}")
        end
      end
      variables = @application_runtime.variables.map do |name, value|
        escaped = value.gsub("%", "%%").gsub('"', '""')
        %(set "#{name}=#{escaped}")
      end
      environment.unshift(*variables)
      environment.unshift(%(set "PATH=%ruby_root%\\bin;%ruby_root%\\lib;%PATH%"))
      <<~CMD.gsub("\n", "\r\n")
        @echo off
        setlocal
        set "bundle_dir=%~dp0"
        set "ruby_root=%bundle_dir%runtime\\ruby"
        set "ZUI_QT_STYLE=#{@qt_configuration.style}"
        #{environment.join("\n")}
        "%bundle_dir%runtime\\native\\#{host}" ^
          --qml-root "%bundle_dir%runtime\\qml" ^
          --project "%bundle_dir%app" ^
          --program #{windows_program} ^
          --ruby "%ruby_root%\\#{executable}" ^
          --load-path #{windows_load_path} ^
          --name #{windows_quote(app_name)}
        exit /b %ERRORLEVEL%
      CMD
    end

    def info_plist(app_name, icon_name: nil)
      identifier = @bundle_config&.identifier || "dev.zui.#{slug(app_name).tr("-", ".")}"
      application_version = @bundle_config&.version || VERSION
      icon_entry = icon_name ? "<key>CFBundleIconFile</key><string>#{xml_escape(icon_name)}</string>" : ""
      <<~PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>CFBundleExecutable</key><string>run</string>
          <key>CFBundleIdentifier</key><string>#{identifier}</string>
          <key>CFBundleName</key><string>#{xml_escape(app_name)}</string>
          <key>CFBundlePackageType</key><string>APPL</string>
          <key>CFBundleShortVersionString</key><string>#{xml_escape(application_version)}</string>
          <key>CFBundleVersion</key><string>#{xml_escape(application_version)}</string>
          #{icon_entry}
          <key>NSHighResolutionCapable</key><true/>
        </dict></plist>
      PLIST
    end

    def write_manifest(directory, app_name)
      manifest = {
        "format" => 1, "framework" => "zui", "version" => VERSION,
        "platform" => platform.os.to_s, "architecture" => platform.arch.to_s,
        "name" => app_name, "client_version" => @client.manifest.fetch("client_version"),
        "tree_shaken" => !@tree_shake_report.nil?, "ruby_runtime" => runtime_mode.to_s,
        "source_date_epoch" => @source_date_epoch
      }
      if @tree_shake_report
        report = @tree_shake_report.to_h
        report["ruby"] = @application_runtime.tree_shake if @application_runtime&.tree_shake
        manifest["tree_shake"] = report
      end
      if @bundle_config
        manifest["identifier"] = @bundle_config.identifier
        manifest["application_version"] = @bundle_config.version
      end
      File.write(File.join(directory, "zui-bundle.json"), JSON.pretty_generate(manifest))
    end

    def finalize_reproducible_bundle(destination)
      manifest_path = if platform.macos?
                        File.join(destination, "Contents", "Resources", "zui-bundle.json")
                      else
                        File.join(destination, "zui-bundle.json")
                      end
      manifest = JSON.parse(File.read(manifest_path))
      manifest["payload_sha256"] = ReproducibleBuild.tree_digest(destination, exclude: [manifest_path])
      File.write(manifest_path, "#{JSON.pretty_generate(manifest)}\n")
      ReproducibleBuild.normalize_tree(destination, epoch: @source_date_epoch)
    end

    def install_macos_release_icon(resources)
      return nil unless @bundle_config

      source = @bundle_config.icon_path(@project, platform)
      name = "Application.icns"
      FileUtils.cp(source, File.join(resources, name))
      name
    end

    def install_windows_release_icon(destination)
      return unless @bundle_config

      FileUtils.cp(@bundle_config.icon_path(@project, platform), File.join(destination, "app.ico"))
    end

    def shake_bundle(project, runtime)
      return unless @tree_shake

      @tree_shake_report = TreeShaker.new(
        project:, framework: File.join(runtime, "qml"), native: File.join(runtime, "native"), platform:
      ).shake!
    end

    def default_destination(project, app_name)
      base = File.join(project, "dist")
      platform.macos? ? File.join(base, "#{app_name}.app") : File.join(base, "#{slug(app_name)}-#{platform.id}")
    end

    def load_project_config(project)
      return unless File.file?(File.join(project, Dist::CONFIG_FILE))

      Dist.load(project:, platform:)
    end

    def configured_release_assets(project)
      return [] unless @bundle_config

      (@bundle_config.icons.values + @bundle_config.splashes.values).filter_map do |relative|
        expanded = File.expand_path(relative, project)
        next unless expanded.start_with?("#{project}#{File::SEPARATOR}") && File.file?(expanded)

        expanded.delete_prefix("#{project}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
      end.uniq.sort
    end

    def titleize(value) = value.split(/[-_]/).map(&:capitalize).join(" ")
    def slug(value) = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    def shell_quote(value) = "'#{value.to_s.gsub("'", %q('"'"'))}'"
    def windows_quote(value) = %Q("#{value.to_s.gsub('%', '%%').gsub('"', '""')}")
    def xml_escape(value) = value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

    def posix_client_environment
      @client.environment_entries.map do |name, paths|
        value = paths.map { |path| "$native_dir/#{path}" }.join(":")
        <<~SH.chomp
          zui_environment="#{value}"
          [ -z "${#{name}:-}" ] || zui_environment="$zui_environment:${#{name}}"
          export #{name}="$zui_environment"
        SH
      end.join("\n")
    end

    def posix_ruby_command
      return posix_private_ruby_command if @application_runtime

      <<~SH.chomp
        ruby_command=${ZUI_RUBY:-}
        if [ -z "$ruby_command" ]; then
          packaged_ruby=#{shell_quote(@ruby)}
          if [ -x "$packaged_ruby" ]; then
            ruby_command=$packaged_ruby
          else
            ruby_command=$(command -v ruby || true)
            [ -n "$ruby_command" ] || ruby_command=ruby
          fi
        fi
      SH
    end

    def posix_private_ruby_command
      lines = ["ruby_root=\"$bundle_dir/runtime/ruby\""]
      if platform.macos?
        lines[0] = "ruby_root=\"$resources/runtime/ruby\""
      end
      @application_runtime.environment.each do |name, paths|
        value = paths.map { |path| "${ruby_root}/#{path}" }.join(File::PATH_SEPARATOR)
        if %w[LD_LIBRARY_PATH DYLD_LIBRARY_PATH].include?(name)
          lines << "zui_environment=\"#{value}\""
          lines << "[ -z \"${#{name}:-}\" ] || zui_environment=\"$zui_environment:${#{name}}\""
          lines << "export #{name}=\"$zui_environment\""
        else
          lines << "export #{name}=\"#{value}\""
        end
      end
      @application_runtime.variables.each do |name, value|
        lines << "export #{name}=#{shell_quote(value)}"
      end
      lines << "ruby_command=\"$ruby_root/#{@application_runtime.executable}\""
      lines.join("\n")
    end

    def posix_program(bundle_root)
      relative = @application_runtime&.program
      relative ? %("#{bundle_root}/runtime/ruby/#{relative}") : %("#{bundle_root}/app/main.rb")
    end

    def posix_load_path(bundle_root)
      relative = @application_runtime&.load_path
      return %("#{bundle_root}/runtime/lib") if relative.nil?
      return '""' if relative.empty?

      %("#{bundle_root}/runtime/ruby/#{relative}")
    end

    def windows_program
      relative = @application_runtime&.program
      return '"%bundle_dir%app\\main.rb"' unless relative

      %("%ruby_root%\\#{relative.tr('/', '\\')}")
    end

    def windows_load_path
      relative = @application_runtime&.load_path
      return '"%bundle_dir%runtime\\lib"' if relative.nil?
      return '""' if relative.empty?

      %("%ruby_root%\\#{relative.tr('/', '\\')}")
    end

    def windows_client_environment = @client.environment_entries

    def windows_environment_builder
      @client.environment_entries.keys.map do |name|
        <<~RUBY.chomp
          values = #{windows_client_environment.fetch(name).inspect}.map { |path| File.join(native_dir, path) }
          values << ENV[#{name.dump}] unless ENV[#{name.dump}].nil? || ENV[#{name.dump}].empty?
          environment[#{name.dump}] = values.join(File::PATH_SEPARATOR)
        RUBY
      end.join("\n")
    end
  end
end
