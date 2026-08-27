# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "shellwords"
require "tmpdir"

module Zui
  class DistPackager
    attr_reader :platform, :config, :tree_shake_report, :runtime_tree_shake_report, :runtime_mode

    def initialize(client: nil, platform: Platform.current, framework_root: FRAMEWORK_ROOT,
                   ruby: RbConfig.ruby, tree_shake: true, environment: ENV, runtime_mode: :lite,
                   runtime_builder: nil)
      @platform = platform.assert_supported!
      @client = client || Client.new(platform: @platform)
      @framework_root = framework_root
      @ruby = File.expand_path(ruby)
      @tree_shake = tree_shake == true
      @runtime_mode = runtime_mode.to_sym
      unless Distribution::RUNTIME_MODES.include?(@runtime_mode)
        raise ArgumentError, "unsupported application runtime: #{runtime_mode}"
      end
      @environment = environment.to_h
      @runtime_builder = runtime_builder
      @source_date_epoch = ReproducibleBuild.epoch(@environment["SOURCE_DATE_EPOCH"])
      @config = nil
      @tree_shake_report = nil
      @runtime_tree_shake_report = nil
    end

    def package(source, output: nil)
      project = File.expand_path(source)
      raise ArgumentError, "project directory not found: #{project}" unless File.directory?(project)

      @project = project
      @config = Dist.load(project:, platform:)
      output = File.expand_path(output || File.join(project, "dist"))
      if File.exist?(output) && !File.directory?(output)
        raise ArgumentError, "distribution output is not a directory: #{output}"
      end
      preflight!
      targets = artifact_names.map { |name| File.join(output, name) }
      existing = targets.find { |path| File.exist?(path) }
      raise ArgumentError, "distribution artifact already exists: #{existing}" if existing

      FileUtils.mkdir_p(output)
      artifacts = []
      Dir.mktmpdir(".zui-dist-", output) do |temporary|
        bundle = build_bundle(project, temporary)
        artifacts = case platform.os
                    when :linux then build_linux_packages(bundle, temporary)
                    when :macos then [build_macos_dmg(bundle, temporary)]
                    when :windows then [build_windows_setup(bundle, temporary)]
                    end
        artifacts.zip(targets).each { |source_path, target| File.rename(source_path, target) }
      end
      targets
    end

    private

    def build_bundle(project, temporary)
      destination = if platform.macos?
                      File.join(temporary, "#{safe_filename(config.name)}.app")
                    else
                      File.join(temporary, "bundle")
                    end
      distribution = Distribution.new(
        client: @client, platform:, framework_root: @framework_root, ruby: @ruby,
        tree_shake: @tree_shake, release_config: config, runtime_mode:,
        runtime_builder: @runtime_builder, source_date_epoch: @source_date_epoch
      )
      distribution.bundle(project, name: config.name, destination:)
      @tree_shake_report = distribution.tree_shake_report
      @runtime_tree_shake_report = distribution.runtime_tree_shake_report
      destination
    end

    def artifact_names
      stem = "#{config.package_name}-#{config.version}-#{platform.id}"
      case platform.os
      when :linux
        ["#{stem}.deb", "#{stem}.rpm"]
      when :macos
        ["#{stem}.dmg"]
      when :windows
        ["#{stem}-setup.exe"]
      end
    end

    def preflight!
      case platform.os
      when :linux
        command!("rpmbuild", hint: "install rpm-build (Debian/Fedora) or rpm-tools (Arch)")
      when :macos
        command!("hdiutil", hint: "install the macOS command-line tools")
      when :windows
        command!("ISCC.exe", "iscc", hint: "install Inno Setup 6 and add ISCC.exe to PATH")
      end
    end

    def build_linux_packages(bundle, temporary)
      stage = File.join(temporary, "linux-root")
      application = File.join(stage, "opt", config.package_name)
      FileUtils.mkdir_p(File.dirname(application))
      FileUtils.cp_r(bundle, application)
      FileUtils.remove_entry(File.join(application, "share")) if File.directory?(File.join(application, "share"))

      command_path = File.join(stage, "usr", "bin", config.package_name)
      FileUtils.mkdir_p(File.dirname(command_path))
      File.write(command_path, <<~SH)
        #!/bin/sh
        exec /opt/#{config.package_name}/run "$@"
      SH
      FileUtils.chmod(0o755, command_path)

      desktop_path = File.join(stage, "usr", "share", "applications", "#{config.package_name}.desktop")
      FileUtils.mkdir_p(File.dirname(desktop_path))
      File.write(desktop_path, linux_desktop_entry)

      icon = config.icon_path(@project, platform)
      extension = File.extname(icon).downcase
      icon_directory = extension == ".svg" ? "scalable" : "256x256"
      installed_icon = File.join(stage, "usr", "share", "icons", "hicolor", icon_directory,
                                 "apps", "#{config.package_name}#{extension}")
      FileUtils.mkdir_p(File.dirname(installed_icon))
      FileUtils.cp(icon, installed_icon)

      deb = File.join(temporary, artifact_names.fetch(0))
      rpm = File.join(temporary, artifact_names.fetch(1))
      build_deb(stage, deb)
      build_rpm(stage, rpm, temporary)
      [deb, rpm]
    end

    def linux_desktop_entry
      categories = config.categories.join(";")
      <<~DESKTOP
        [Desktop Entry]
        Type=Application
        Name=#{config.name}
        Comment=#{config.description}
        Exec=/opt/#{config.package_name}/run
        Icon=#{config.package_name}
        Terminal=false
        Categories=#{categories};
      DESKTOP
    end

    def build_deb(stage, output)
      workspace = File.join(File.dirname(output), "deb-work")
      FileUtils.mkdir_p(workspace)
      control = File.join(workspace, "control")
      File.write(control, deb_control(stage))
      debian_binary = File.join(workspace, "debian-binary")
      File.write(debian_binary, "2.0\n")
      control_archive = File.join(workspace, "control.tar.gz")
      data_archive = File.join(workspace, "data.tar.gz")
      gzip_tar(control_archive, workspace, ["control"])
      gzip_tar(data_archive, stage, Dir.children(stage).sort)
      write_ar(output, [debian_binary, control_archive, data_archive])
    end

    def deb_control(stage)
      installed_size = (tree_bytes(stage) / 1024.0).ceil
      values = [
        "Package: #{config.package_name}",
        "Version: #{config.version}",
        "Section: utils",
        "Priority: optional",
        "Architecture: #{deb_architecture}",
        "Maintainer: #{config.publisher}",
        "Installed-Size: #{installed_size}",
        "Description: #{config.description}"
      ]
      values.insert(-2, "Homepage: #{config.homepage}") if config.homepage
      "#{values.join("\n")}\n"
    end

    def build_rpm(stage, output, temporary)
      topdir = File.join(temporary, "rpmbuild")
      %w[BUILD BUILDROOT RPMS SOURCES SPECS SRPMS].each { |name| FileUtils.mkdir_p(File.join(topdir, name)) }
      spec = File.join(topdir, "SPECS", "#{config.package_name}.spec")
      File.write(spec, rpm_spec(stage))
      rpmbuild = command!("rpmbuild", hint: "install rpm-build (Debian/Fedora) or rpm-tools (Arch)")
      arguments = [
        rpmbuild,
        "--define", "_topdir #{topdir}",
        "--define", "_buildhost reproducible",
        "--define", "_buildtime #{@source_date_epoch}",
        "--define", "use_source_date_epoch_as_buildtime 1",
        "--define", "clamp_mtime_to_source_date_epoch 1",
        "--define", "build_mtime_policy clamp_to_source_date_epoch",
        "-bb", spec
      ]
      run!(arguments, timeout: 900, env: { "SOURCE_DATE_EPOCH" => @source_date_epoch.to_s })
      built = Dir[File.join(topdir, "RPMS", "**", "*.rpm")].sort
      raise ArgumentError, "rpmbuild did not produce an RPM artifact" unless built.length == 1

      FileUtils.cp(built.first, output)
    end

    def rpm_spec(stage)
      description = rpm_escape(config.description)
      homepage = config.homepage ? "URL: #{rpm_escape(config.homepage)}\n" : ""
      <<~SPEC
        %global debug_package %{nil}
        %global __os_install_post %{nil}
        %global _build_id_links none
        Name: #{config.package_name}
        Version: #{config.version}
        Release: 1
        Summary: #{description}
        License: #{rpm_escape(config.license)}
        #{homepage}BuildArch: #{rpm_architecture}
        AutoReqProv: no

        %description
        #{description}

        %install
        rm -rf "%{buildroot}"
        mkdir -p "%{buildroot}"
        cp -a #{Shellwords.escape(stage)}/. "%{buildroot}/"

        %files
        /opt/#{config.package_name}
        /usr/bin/#{config.package_name}
        /usr/share/applications/#{config.package_name}.desktop
        /usr/share/icons/hicolor
      SPEC
    end

    def build_macos_dmg(bundle, temporary)
      root = File.join(temporary, "dmg-root")
      FileUtils.mkdir_p(root)
      FileUtils.cp_r(bundle, root, preserve: true)
      File.symlink("/Applications", File.join(root, "Applications"))
      ReproducibleBuild.normalize_tree(root, epoch: @source_date_epoch)
      hybrid = File.join(temporary, "deterministic-udf.iso")
      output = File.join(temporary, artifact_names.first)
      hdiutil = command!("hdiutil", hint: "install the macOS command-line tools")
      run!([hdiutil, "makehybrid", "-udf", "-udf-volume-name", config.name,
            "-o", hybrid, root], timeout: 900)
      ReproducibleBuild.normalize_udf(
        hybrid, epoch: @source_date_epoch, volume_id: "#{config.identifier}\0#{config.version}"
      )
      run!([hdiutil, "convert", hybrid, "-format", "UDZO", "-o", output], timeout: 900)
      raise ArgumentError, "hdiutil did not produce a DMG artifact" unless File.file?(output)

      ReproducibleBuild.normalize_udif_segment_id(output)
      output
    end

    def build_windows_setup(bundle, temporary)
      output_name = File.basename(artifact_names.first, ".exe")
      script = File.join(temporary, "installer.iss")
      File.write(script, windows_inno_script(bundle, temporary, output_name))
      iscc = command!("ISCC.exe", "iscc", hint: "install Inno Setup 6 and add ISCC.exe to PATH")
      run!([iscc, "--no-ide-signtools", "--no-signing", script], timeout: 900)
      output = File.join(temporary, "#{output_name}.exe")
      raise ArgumentError, "Inno Setup did not produce a setup executable" unless File.file?(output)

      output
    end

    def windows_inno_script(bundle, output, output_name)
      architectures = platform.arch == :arm64 ? "arm64" : "x64compatible"
      <<~ISS
        [Setup]
        AppId=#{inno(config.identifier)}
        AppName=#{inno(config.name)}
        AppVersion=#{inno(config.version)}
        AppPublisher=#{inno(config.publisher)}
        AppPublisherURL=#{inno(config.homepage || "")}
        DefaultDirName={autopf}\\#{inno(config.name)}
        DefaultGroupName=#{inno(config.name)}
        OutputDir=#{inno(output)}
        OutputBaseFilename=#{inno(output_name)}
        SetupIconFile=#{inno(File.join(bundle, "app.ico"))}
        UninstallDisplayIcon={app}\\app.ico
        Compression=lzma2
        CompressionThreads=1
        LZMANumBlockThreads=1
        SolidCompression=yes
        TimeStampsInUTC=yes
        TimeStampRounding=1
        WizardStyle=modern
        ArchitecturesAllowed=#{architectures}
        ArchitecturesInstallIn64BitMode=#{architectures}

        [Files]
        #{windows_file_entries(bundle)}

        [Icons]
        Name: "{autoprograms}\\#{inno(config.name)}"; Filename: "{app}\\run.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\\app.ico"
        Name: "{autodesktop}\\#{inno(config.name)}"; Filename: "{app}\\run.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\\app.ico"
      ISS
    end

    def gzip_tar(output, root, entries)
      ReproducibleBuild.tar_gzip(output, root:, entries:, epoch: @source_date_epoch, prefix: ".")
    end

    def write_ar(output, files)
      File.open(output, "wb", 0o644) do |archive|
        archive.write("!<arch>\n")
        files.each do |path|
          size = File.size(path)
          name = "#{File.basename(path)}/"
          header = format("%-16s%-12d%-6d%-6d%-8s%-10d`\n",
                          name, 0, 0, 0, "100644", size)
          raise ArgumentError, "invalid Debian archive header" unless header.bytesize == 60

          archive.write(header)
          File.open(path, "rb") { |file| IO.copy_stream(file, archive) }
          archive.write("\n") if size.odd?
        end
      end
    end

    def command!(*names, hint:)
      candidates = names.dup
      if platform.windows?
        extensions = @environment.fetch("PATHEXT", ".EXE;.CMD;.BAT").split(";")
        candidates += names.flat_map { |name| extensions.map { |extension| "#{name}#{extension}" } }
      end
      @environment.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
        candidates.each do |name|
          path = File.join(directory, name)
          return path if File.file?(path) && File.executable?(path)
        end
      end
      if platform.windows?
        [@environment["ProgramFiles(x86)"], @environment["ProgramFiles"]].compact.each do |root|
          path = File.join(root, "Inno Setup 6", "ISCC.exe")
          return path if File.file?(path)
        end
      end
      raise ArgumentError, "distribution packaging requires #{names.join(' or ')}; #{hint}"
    end

    def run!(arguments, timeout:, env: {})
      result = Command.run(arguments, env:, timeout:, max_output_bytes: 8_000_000)
      return result if result.success?

      details = [result.stdout, result.stderr].reject(&:empty?).join("\n").strip
      message = "distribution command failed (#{File.basename(arguments.first)}), exit #{result.exitstatus}"
      raise ArgumentError, details.empty? ? message : "#{message}:\n#{details}"
    rescue CommandTimeout, CommandOutputLimit => error
      raise ArgumentError, error.message
    end

    def safe_filename(value) = value.gsub(/[\\\/:*?"<>|]/, "-")
    def rpm_escape(value) = value.to_s.gsub("%", "%%")
    def inno(value) = value.to_s.gsub("{", "{{").gsub('"', '""')
    def deb_architecture = platform.arch == :arm64 ? "arm64" : "amd64"
    def rpm_architecture = platform.arch == :arm64 ? "aarch64" : "x86_64"
    def tree_bytes(root) = Dir[File.join(root, "**", "*")].sum { |path| File.file?(path) ? File.size(path) : 0 }

    def windows_file_entries(bundle)
      files = Dir.glob(File.join(bundle, "**", "*"), File::FNM_DOTMATCH).select do |path|
        File.file?(path) && !File.symlink?(path) && !%w[. ..].include?(File.basename(path))
      end
      files.sort.map do |path|
        relative = path.delete_prefix("#{bundle}#{File::SEPARATOR}")
        directory = File.dirname(relative)
        destination = directory == "." ? "{app}" : "{app}\\#{directory.tr('/', '\\')}"
        %(Source: "#{inno(path)}"; DestDir: "#{inno(destination)}"; Flags: ignoreversion notimestamp)
      end.join("\n")
    end
  end
end
