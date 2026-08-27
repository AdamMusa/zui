# frozen_string_literal: true

require "fileutils"
require "json"
require "rbconfig"
require "set"

module Zui
  class FullRuntime
    SYSTEM_LIBRARIES = /\A(?:ld-linux|libc\.|libdl\.|libgcc_s\.|libm\.|libpthread\.|librt\.|libSystem\.|libutil\.)/.freeze

    attr_reader :platform

    def initialize(platform: Platform.current, ruby: RbConfig.ruby, environment: ENV,
                   rbconfig: RbConfig::CONFIG, spec_loader: nil)
      @platform = platform.assert_supported!
      @ruby = File.expand_path(ruby)
      @environment = environment.to_h
      @rbconfig = rbconfig.to_h
      @spec_loader = spec_loader || LockedGems.new(environment: @environment).method(:specs)
    end

    def install(project:, destination:)
      project = File.expand_path(project)
      destination = File.expand_path(destination)
      raise ArgumentError, "Ruby executable not found: #{@ruby}" unless File.file?(@ruby)
      raise ArgumentError, "full runtime destination already exists: #{destination}" if File.exist?(destination)

      FileUtils.mkdir_p(destination)
      executable = install_executable(destination)
      library_paths = install_standard_library(destination)
      install_runtime_libraries(destination)
      gems = install_project_gems(project, destination)
      install_native_dependencies(destination)
      environment = {
        "RUBYLIB" => library_paths,
        "GEM_HOME" => ["gems"],
        "GEM_PATH" => ["gems"]
      }
      dynamic_library_variable = platform.macos? ? "DYLD_LIBRARY_PATH" : "LD_LIBRARY_PATH"
      environment[dynamic_library_variable] = ["lib"] unless platform.windows?

      ApplicationRuntime.new(
        engine: "cruby",
        version: ruby_version,
        executable:,
        environment:,
        gems: gems.map(&:full_name)
      ).write(destination)
    rescue StandardError
      FileUtils.remove_entry(destination) if destination && File.exist?(destination)
      raise
    end

    private

    def install_executable(destination)
      name = platform.windows? ? "ruby.exe" : "ruby"
      target = File.join(destination, "bin", name)
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(@ruby, target)
      FileUtils.chmod(0o755, target) unless platform.windows?
      strip_binary(target)
      sign_binary(target)
      File.join("bin", name).tr(File::SEPARATOR, "/")
    end

    def install_standard_library(destination)
      sources = [@rbconfig["rubylibdir"], @rbconfig["archdir"]].compact.map { |path| File.expand_path(path) }
      sources.select! { |path| File.directory?(path) }
      raise ArgumentError, "Ruby standard library was not found" if sources.empty?

      entries = sources.map do |source|
        { source:, relative: runtime_relative_path(source) }
      end
      installed = []
      entries.sort_by { |entry| entry.fetch(:source).length }.each do |entry|
        source = entry.fetch(:source)
        relative = entry.fetch(:relative)
        target = File.join(destination, relative)
        next if installed.any? { |entry| inside?(target, entry.fetch(:target)) }

        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp_r(source, target)
        installed << { source:, target:, relative: relative.tr(File::SEPARATOR, "/") }
      end
      entries.map { |entry| entry.fetch(:relative).tr(File::SEPARATOR, "/") }.uniq
    end

    def install_runtime_libraries(destination)
      patterns = if platform.windows?
                   [File.join(@rbconfig.fetch("bindir", File.dirname(@ruby)), "*.dll")]
                 else
                   libdir = @rbconfig["libdir"]
                   libdir ? [File.join(libdir, "libruby*.so*"), File.join(libdir, "libruby*.dylib")] : []
                 end
      target = platform.windows? ? File.join(destination, "bin") : File.join(destination, "lib")
      FileUtils.mkdir_p(target)
      patterns.flat_map { |pattern| Dir[pattern] }.uniq.each do |source|
        next unless File.file?(source)

        installed = File.join(target, File.basename(source))
        if File.symlink?(source)
          FileUtils.ln_s(File.readlink(source), installed)
        else
          FileUtils.cp(source, installed)
        end
      end
    end

    def install_native_dependencies(destination)
      return if platform.windows?

      library_root = File.join(destination, "lib")
      FileUtils.mkdir_p(library_root)
      binaries = [File.join(destination, "bin", "ruby")]
      binaries.concat(Dir[File.join(destination, "**", "*.{bundle,so,dylib}")])
      inspected = Set.new
      until binaries.empty?
        binary = binaries.shift
        next unless File.file?(binary) && inspected.add?(binary)

        dependencies(binary).each do |source|
          name = File.basename(source)
          next if SYSTEM_LIBRARIES.match?(name)

          target = File.join(library_root, name)
          next if File.file?(target)

          FileUtils.cp(source, target)
          binaries << target
        end
      end
    end

    def dependencies(binary)
      if platform.linux?
        output = IO.popen(["ldd", binary], err: File::NULL, &:read)
        output.lines.filter_map do |line|
          path = line[/=>\s+(\/\S+)/, 1] || line[/^\s*(\/\S+)/, 1]
          path if path && File.file?(path)
        end
      else
        output = IO.popen(["otool", "-L", binary], err: File::NULL, &:read)
        output.lines.drop(1).filter_map do |line|
          path = line.strip.split.first
          next if path.nil? || path.start_with?("/System/", "/usr/lib/") || path.start_with?("@")

          path if File.file?(path)
        end
      end
    rescue Errno::ENOENT
      []
    end

    def install_project_gems(project, destination)
      specs = @spec_loader.call(project).reject { |spec| spec.name == "zui" || spec.default_gem? }
      gem_home = File.join(destination, "gems")
      FileUtils.mkdir_p([File.join(gem_home, "gems"), File.join(gem_home, "specifications")])
      names = Set.new
      specs.sort_by(&:full_name).each do |spec|
        raise ArgumentError, "duplicate bundled gem: #{spec.full_name}" unless names.add?(spec.full_name)
        unless File.directory?(spec.full_gem_path)
          raise ArgumentError, "project gem is not installed: #{spec.full_name}; run `bundle install`"
        end

        FileUtils.cp_r(spec.full_gem_path, File.join(gem_home, "gems", spec.full_name))
        File.write(File.join(gem_home, "specifications", "#{spec.full_name}.gemspec"), spec.to_ruby)
        install_gem_extensions(spec, gem_home)
      end
      specs
    end

    def install_gem_extensions(spec, gem_home)
      source = spec.extension_dir
      return unless source && File.directory?(source)

      parts = File.expand_path(source).split(File::SEPARATOR)
      index = parts.rindex("extensions")
      return unless index

      relative = File.join(*parts[(index + 1)..])
      target = File.join(gem_home, "extensions", relative)
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp_r(source, target)
    end

    def runtime_relative_path(path)
      prefix = File.expand_path(@rbconfig.fetch("prefix"))
      return path.delete_prefix("#{prefix}#{File::SEPARATOR}") if inside?(path, prefix)

      File.join("lib", "ruby", File.basename(path))
    end

    def ruby_version
      @rbconfig["RUBY_PROGRAM_VERSION"] || RUBY_VERSION
    end

    def inside?(path, parent)
      path == parent || path.start_with?("#{parent}#{File::SEPARATOR}")
    end

    def strip_binary(path)
      magic = File.binread(path, 4)
      mach_o = ["\xCF\xFA\xED\xFE".b, "\xFE\xED\xFA\xCF".b, "\xCA\xFE\xBA\xBE".b]
      return unless magic.start_with?("\x7FELF".b, "MZ".b) || mach_o.include?(magic)

      strip = find_command(platform.macos? ? %w[strip] : %w[strip llvm-strip])
      return unless strip

      arguments = platform.macos? ? [strip, "-x", path] : [strip, "--strip-unneeded", path]
      system(*arguments, out: File::NULL, err: File::NULL)
    end

    def sign_binary(path)
      return unless platform.macos?

      codesign = find_command(%w[codesign])
      raise ArgumentError, "codesign is required to build a macOS full runtime" unless codesign

      signed = system(codesign, "--force", "--sign", "-", "--timestamp=none", path,
                      out: File::NULL, err: File::NULL)
      raise ArgumentError, "failed to sign the bundled Ruby executable" unless signed
    end

    def find_command(names)
      @environment.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
        names.each do |name|
          path = File.join(directory, name)
          return path if File.file?(path) && File.executable?(path)
        end
      end
      nil
    end
  end
end
