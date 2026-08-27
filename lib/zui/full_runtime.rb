# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "rbconfig"
require "set"

module Zui
  class FullRuntime
    SYSTEM_LIBRARIES = /\A(?:ld-linux|libc\.|libdl\.|libgcc_s\.|libm\.|libpthread\.|librt\.|libSystem\.|libutil\.)/.freeze
    ZUI_RUNTIME_FILES = %w[
      lib/zui.rb
      lib/zui/animation.rb
      lib/zui/application.rb
      lib/zui/builder.rb
      lib/zui/component_registry.rb
      lib/zui/components.rb
      lib/zui/node.rb
      lib/zui/protocol.rb
      lib/zui/runtime_entry.rb
      lib/zui/scheduler.rb
      lib/zui/state_store.rb
      lib/zui/value.rb
    ].freeze
    ZUI_RUNTIME_ENTRYPOINT = <<~RUBY.freeze
      # frozen_string_literal: true

      require_relative "zui/runtime_entry"
    RUBY
    EXTENSION_BUILD_FILES = %w[.DS_Store Makefile gem_make.out mkmf.log].freeze
    EXTENSION_BUILD_EXTENSIONS = %w[.a .exp .ilk .lib .o .obj .pdb].freeze
    NON_RUNTIME_DIRECTORIES = %w[.dSYM].freeze

    attr_reader :platform, :tree_shake_report

    def initialize(platform: Platform.current, ruby: RbConfig.ruby, environment: ENV,
                   rbconfig: RbConfig::CONFIG, spec_loader: nil, tree_shake: true)
      @platform = platform.assert_supported!
      @ruby = File.expand_path(ruby)
      @environment = environment.to_h
      @rbconfig = rbconfig.to_h
      @spec_loader = spec_loader || LockedGems.new(environment: @environment).method(:specs)
      @tree_shake = tree_shake == true
      @tree_shake_report = nil
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
      prune_non_runtime_artifacts(destination)
      @tree_shake_report = shake_standard_library(project, destination, library_paths) if @tree_shake
      install_native_dependencies(destination)
      optimize_native_binaries(destination)
      library_paths += gem_load_paths(destination, gems)
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
        variables: tree_shake_report&.tree_shaken? ? { "RUBYOPT" => "--disable-gems" } : {},
        gems: gems.map(&:full_name),
        load_path: "",
        tree_shake: tree_shake_report&.to_h
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
          if File.file?(target)
            identical = File.size(target) == File.size(source) &&
                        Digest::SHA256.file(target).digest == Digest::SHA256.file(source).digest
            unless identical
              raise ArgumentError, "native dependency collision for #{name}: #{source}"
            end
            next
          end

          FileUtils.cp(source, target)
          binaries << target
        end
      end
    end

    def shake_standard_library(project, destination, library_paths)
      configuration = QtBundleConfiguration.load(project)
      RubyRuntimeShaker.new(
        project:,
        runtime: destination,
        load_paths: library_paths,
        configured_features: configuration.ruby_stdlib
      ).shake!
    end

    def gem_load_paths(destination, specs)
      paths = specs.flat_map do |spec|
        require_paths = spec.respond_to?(:require_paths) ? Array(spec.require_paths) : ["lib"]
        require_paths.map { |path| File.join("gems", "gems", spec.full_name, path) }
      end
      specs.each do |spec|
        root = File.join(destination, "gems", "extensions")
        Dir.glob(File.join(root, "**", spec.full_name)).sort.each do |path|
          paths << path.delete_prefix("#{destination}#{File::SEPARATOR}") if File.directory?(path)
        end
      end
      paths.map { |path| path.tr(File::SEPARATOR, "/") }.uniq.sort
    end

    def prune_non_runtime_artifacts(destination)
      paths = Dir.glob(File.join(destination, "**", "*"), File::FNM_DOTMATCH).sort_by do |path|
        -path.count(File::SEPARATOR)
      end
      paths.each do |path|
        name = File.basename(path)
        if File.directory?(path) && NON_RUNTIME_DIRECTORIES.any? { |suffix| name.end_with?(suffix) }
          FileUtils.remove_entry(path)
        elsif File.file?(path) && EXTENSION_BUILD_FILES.include?(name)
          FileUtils.rm_f(path)
        elsif File.file?(path) && EXTENSION_BUILD_EXTENSIONS.include?(File.extname(name).downcase)
          FileUtils.rm_f(path)
        end
      end
    end

    def optimize_native_binaries(destination)
      patterns = platform.windows? ? %w[*.dll *.exe] : %w[*.bundle *.dylib *.so]
      binaries = patterns.flat_map { |pattern| Dir.glob(File.join(destination, "**", pattern)) }
      executable = File.join(destination, "bin", platform.windows? ? "ruby.exe" : "ruby")
      binaries << executable if File.file?(executable)
      binaries.uniq.sort.each do |path|
        next if File.symlink?(path) || !native_binary?(path)

        strip_binary(path)
        sign_binary(path)
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
      specs = @spec_loader.call(project).reject(&:default_gem?)
      gem_home = File.join(destination, "gems")
      FileUtils.mkdir_p([File.join(gem_home, "gems"), File.join(gem_home, "specifications")])
      names = Set.new
      specs.sort_by(&:full_name).each do |spec|
        raise ArgumentError, "duplicate bundled gem: #{spec.name}" unless names.add?(spec.name)
        unless File.directory?(spec.full_gem_path)
          raise ArgumentError, "project gem is not installed: #{spec.full_name}; run `bundle install`"
        end

        files = packaged_gem_files(spec)
        gem_target = File.join(gem_home, "gems", spec.full_name)
        install_gem_files(spec, gem_target, files:)
        install_zui_runtime_entrypoint(gem_target) if spec.name == "zui"
        File.write(
          File.join(gem_home, "specifications", "#{spec.full_name}.gemspec"),
          spec.to_ruby(files:)
        )
        install_gem_extensions(spec, gem_home)
      end
      specs
    end

    def install_gem_files(spec, target, files: packaged_gem_files(spec))
      if files.empty?
        raise ArgumentError, "gem #{spec.full_name} has no packaged files; set spec.files in its gemspec"
      end

      root = File.realpath(spec.full_gem_path)
      FileUtils.mkdir_p(target)
      files.each do |relative|
        source = File.expand_path(relative, root)
        unless inside?(source, root)
          raise ArgumentError, "gem #{spec.full_name} has an unsafe packaged path: #{relative.inspect}"
        end
        unless File.file?(source)
          raise ArgumentError, "gem #{spec.full_name} is missing packaged file: #{relative}"
        end
        unless inside?(File.realpath(source), root)
          raise ArgumentError, "gem #{spec.full_name} has a packaged symlink outside its root: #{relative.inspect}"
        end

        destination = File.join(target, relative)
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination, preserve: true)
      end
    end

    def packaged_gem_files(spec)
      files = Array(spec.files).map(&:to_s).reject(&:empty?).uniq.sort
      return files unless spec.name == "zui"

      files & ZUI_RUNTIME_FILES
    end

    def install_zui_runtime_entrypoint(target)
      runtime = File.join(target, "lib", "zui", "runtime_entry.rb")
      unless File.file?(runtime)
        raise ArgumentError, "zui runtime entrypoint is missing: lib/zui/runtime_entry.rb"
      end

      File.write(File.join(target, "lib", "zui.rb"), ZUI_RUNTIME_ENTRYPOINT)
    end

    def install_gem_extensions(spec, gem_home)
      source = spec.extension_dir
      return unless source && File.directory?(source)

      parts = File.expand_path(source).split(File::SEPARATOR)
      index = parts.rindex("extensions")
      return unless index

      relative = File.join(*parts[(index + 1)..])
      target = File.join(gem_home, "extensions", relative)
      root = File.realpath(source)
      Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH).sort.each do |path|
        next unless File.file?(path)

        name = File.basename(path)
        next if EXTENSION_BUILD_FILES.include?(name)
        next if EXTENSION_BUILD_EXTENSIONS.include?(File.extname(name).downcase)

        resolved = File.realpath(path)
        unless inside?(resolved, root)
          raise ArgumentError, "gem #{spec.full_name} has an extension file outside its root: #{path}"
        end
        extension_relative = path.delete_prefix("#{source}#{File::SEPARATOR}")
        installed = File.join(target, extension_relative)
        FileUtils.mkdir_p(File.dirname(installed))
        FileUtils.cp(path, installed, preserve: true)
      end
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
      strip = find_command(platform.macos? ? %w[strip] : %w[strip llvm-strip])
      return unless strip

      arguments = platform.macos? ? [strip, "-x", path] : [strip, "--strip-unneeded", path]
      system(*arguments, out: File::NULL, err: File::NULL)
    end

    def native_binary?(path)
      magic = File.binread(path, 4)
      mach_o = ["\xCF\xFA\xED\xFE".b, "\xFE\xED\xFA\xCF".b, "\xCA\xFE\xBA\xBE".b]
      magic.start_with?("\x7FELF".b, "MZ".b) || mach_o.include?(magic)
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
