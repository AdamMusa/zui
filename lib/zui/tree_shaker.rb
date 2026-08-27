# frozen_string_literal: true

require "fileutils"
require "json"
require "ripper"
require "set"

module Zui
  class TreeShaker
    CONFIG_FILE = QtBundleConfiguration::CONFIG_FILE
    EXCLUDED_SOURCE_DIRECTORIES = %w[.git dist node_modules spec test tmp vendor].freeze
    EXCLUDED_SOURCE_FILES = %w[config.rb].freeze
    BASE_COMPONENTS = %i[container].freeze
    RUBY_ONLY_DSL_METHODS = %w[animation state].freeze
    COMPONENT_DISPATCH_METHODS = %w[component dynamic qml_component send public_send widget].freeze
    BASE_QML_MODULES = %w[
      QML QtCore QtQml QtQml.Models QtQml.WorkerScript QtQuick QtQuick.Window
      QtQuick.Controls QtQuick.Controls.impl QtQuick.Layouts QtQuick.Templates
    ].freeze
    IMAGE_FORMAT_FEATURES = {
      "gif" => "gif", "ico" => "ico", "jpg" => "jpeg", "jpeg" => "jpeg",
      "svg" => "svg", "svgz" => "svg", "webp" => "webp"
    }.freeze
    IMAGE_PLUGIN_FEATURES = {
      "qgif" => "gif", "qico" => "ico", "qjpeg" => "jpeg", "qsvg" => "svg",
      "qwebp" => "webp"
    }.freeze
    TEXT_INPUT_COMPONENTS = %i[
      color_picker date_picker double_spin_box file_picker folder_picker font_picker number_field
      password_field search_field spin_box text_area text_field time_picker
    ].freeze

    Report = Struct.new(:components, :qml_modules, :qt_style, :qt_features, :qt_plugins,
                        :before_bytes, :after_bytes, :warnings,
                        keyword_init: true) do
      def saved_bytes = before_bytes - after_bytes

      def to_h
        {
          "components" => components.map(&:to_s),
          "qml_modules" => qml_modules,
          "qt" => {
            "style" => qt_style,
            "features" => qt_features,
            "plugins" => qt_plugins
          },
          "before_bytes" => before_bytes,
          "after_bytes" => after_bytes,
          "saved_bytes" => saved_bytes,
          "warnings" => warnings
        }
      end
    end

    def initialize(project:, framework:, native:, platform: Platform.current)
      @project = File.expand_path(project)
      @framework = File.expand_path(framework)
      @native = File.expand_path(native)
      @platform = platform.assert_supported!
      @configuration = QtBundleConfiguration.load(@project)
      @warnings = []
    end

    def shake!
      before_bytes = tree_bytes(@framework) + tree_bytes(@native)
      components, adapters = analyze_components
      @qt_features = detected_qt_features
      prune_framework(adapters)
      imports = qml_imports(Dir[File.join(@framework, "**", "*.qml")])
      qml_modules = prune_native_qml(imports)
      prune_native_plugins(components, qml_modules)
      prune_translations
      prune_native_libraries
      update_client_manifest(components, qml_modules)
      after_bytes = tree_bytes(@framework) + tree_bytes(@native)
      Report.new(components: components.sort, qml_modules: qml_modules.sort,
                 qt_style: @configuration.style, qt_features: @qt_features.to_a.sort,
                 qt_plugins: retained_native_plugins,
                 before_bytes:, after_bytes:, warnings: @warnings.dup.freeze)
    end

    private

    def analyze_components
      known = COMPONENTS.keys.to_h { |name| [name.to_s, name] }
      selected = Set.new(BASE_COMPONENTS)
      ruby_sources.each do |path|
        syntax = Ripper.sexp(File.read(path))
        raise ArgumentError, "cannot tree-shake Ruby file with syntax errors: #{path}" unless syntax

        component_references(syntax, known).each { |component| selected << component }
      end
      @configuration.components.each do |name|
        selected << known.fetch(name) do
          raise ArgumentError, "unknown component in #{CONFIG_FILE}: #{name}"
        end
      end

      adapters_by_type = COMPONENTS.keys.to_h { |name| [name, adapter_name(name)] }
      types_by_adapter = adapters_by_type.invert
      adapters = Set.new(selected.map { |name| adapters_by_type.fetch(name) })
      queue = adapters.to_a
      until queue.empty?
        adapter = queue.shift
        path = File.join(@framework, "Components", "Builtins", adapter)
        raise ArgumentError, "component adapter is missing while tree-shaking: #{path}" unless File.file?(path)

        File.read(path).scan(/\bBuiltins\.([A-Z][A-Za-z0-9]*)/).flatten.each do |class_name|
          dependency = "#{class_name}.qml"
          next unless types_by_adapter.key?(dependency) && adapters.add?(dependency)

          selected << types_by_adapter.fetch(dependency)
          queue << dependency
        end
      end
      [selected.to_a, adapters]
    end

    def component_references(node, known, found = Set.new)
      return found unless node.is_a?(Array)

      case node.first
      when :vcall, :fcall
        add_method_reference(found, known, identifier_value(node[1]))
      when :command
        method_name = identifier_value(node[1])
        add_method_reference(found, known, method_name)
        add_literal_references(found, known, node[2]) if COMPONENT_DISPATCH_METHODS.include?(method_name)
      when :method_add_arg
        method_name = call_name(node[1])
        add_method_reference(found, known, method_name)
        add_literal_references(found, known, node[2]) if COMPONENT_DISPATCH_METHODS.include?(method_name)
      end
      node.each { |child| component_references(child, known, found) if child.is_a?(Array) }
      found
    end

    def call_name(node)
      return nil unless node.is_a?(Array)
      return identifier_value(node[1]) if %i[fcall vcall].include?(node.first)
      nil
    end

    def identifier_value(node)
      node.is_a?(Array) && node.first.to_s.start_with?("@") ? node[1].to_s : nil
    end

    def literal_values(node, values = [])
      return values unless node.is_a?(Array)

      if node.first == :symbol_literal
        token = node.flatten.find { |part| part.is_a?(String) }
        values << token if token
      elsif node.first == :string_literal
        token = node.flatten.find { |part| part.is_a?(String) }
        values << token if token
      else
        node.each { |child| literal_values(child, values) if child.is_a?(Array) }
      end
      values
    end

    def add_known_reference(found, known, value)
      component = known[value]
      found << component if component
    end

    def add_method_reference(found, known, value)
      return if RUBY_ONLY_DSL_METHODS.include?(value)

      add_known_reference(found, known, value)
    end

    def add_literal_references(found, known, arguments)
      literal_values(arguments).each { |value| add_known_reference(found, known, value) }
    end

    def ruby_sources
      Dir[File.join(@project, "**", "*.rb")].select do |path|
        relative = path.delete_prefix("#{@project}#{File::SEPARATOR}")
        !EXCLUDED_SOURCE_FILES.include?(relative) &&
          !EXCLUDED_SOURCE_DIRECTORIES.include?(relative.split(File::SEPARATOR).first)
      end.sort
    end

    def adapter_name(name)
      "#{name.to_s.split('_').map(&:capitalize).join}.qml"
    end

    def prune_framework(adapters)
      builtins = File.join(@framework, "Components", "Builtins")
      Dir[File.join(builtins, "*.qml")].each do |path|
        FileUtils.rm_f(path) unless adapters.include?(File.basename(path))
      end
      sources = adapters.map { |name| File.join(builtins, name) }
      prune_framework_support(File.join(builtins, "Support"), sources)
      shaders_required = adapters.include?("ShaderEffect.qml")
      remove_tree(File.join(builtins, "Shaders")) unless shaders_required
    end

    def prune_framework_support(root, adapter_sources)
      return unless File.directory?(root)

      available = Dir[File.join(root, "**", "{*.qml,*.js}")].to_h do |path|
        [path.delete_prefix("#{root}#{File::SEPARATOR}"), path]
      end
      by_component = available.each_with_object({}) do |(relative, _path), components|
        components[File.basename(relative, ".qml")] = relative if relative.end_with?(".qml")
      end
      required = Set.new
      queue = adapter_sources.dup
      until queue.empty?
        source_path = queue.shift
        source = File.read(source_path)
        support_references(source, source_path.start_with?("#{root}#{File::SEPARATOR}"), by_component).each do |relative|
          path = available[relative]
          next unless path && required.add?(path)

          queue << path
        end
      end

      return remove_tree(root) if required.empty?

      available.each_value { |path| FileUtils.rm_f(path) unless required.include?(path) }
      Dir[File.join(root, "**", "*")].sort_by { |path| -path.count(File::SEPARATOR) }.each do |path|
        Dir.rmdir(path) if File.directory?(path) && Dir.empty?(path)
      end
    end

    def support_references(source, support_source, by_component)
      references = Set.new
      source.scan(/\bSupport\.([A-Z][A-Za-z0-9_]*)\b/) do |match|
        references << "#{match.first}.qml"
      end
      source.scan(/["']Support\/([^"']+\.(?:qml|js))["']/) do |match|
        references << match.first
      end
      if support_source
        by_component.each do |name, relative|
          references << relative if source.match?(/\b#{Regexp.escape(name)}\s*\{/)
        end
        source.scan(/["']([^"']+\.(?:qml|js))["']/) do |match|
          references << match.first unless match.first.include?("..")
        end
      end
      references
    end

    def qml_imports(paths)
      paths.each_with_object(Set.new) do |path, imports|
        File.foreach(path) do |line|
          line.scan(/(?:^|["'])\s*import\s+([A-Za-z][A-Za-z0-9_.]*)\b/) do |match|
            imports << match.first
          end
        end
      end
    end

    def prune_native_qml(framework_imports)
      root = native_path_for("QML_IMPORT_PATH")
      return [] unless root && File.directory?(root)

      modules = module_directories(root)
      style_module = "QtQuick.Controls.#{@configuration.style}"
      missing = @configuration.qml_modules.reject { |name| modules.key?(name) }
      if @configuration.style_explicit? && !modules.key?(style_module)
        missing << style_module
      end
      unless missing.empty?
        raise ArgumentError, "configured Qt QML module is unavailable: #{missing.sort.join(', ')}"
      end
      explicitly_required = @configuration.qml_modules.dup
      explicitly_required << style_module if modules.key?(style_module)
      required = Set.new((BASE_QML_MODULES + framework_imports.to_a + explicitly_required)
                           .select { |name| modules.key?(name) })
      queue = required.to_a
      until queue.empty?
        name = queue.shift
        module_imports(modules.fetch(name), modules).each do |dependency|
          next unless modules.key?(dependency) && required.add?(dependency)

          queue << dependency
        end
      end

      modules.sort_by { |_name, path| -path.count(File::SEPARATOR) }.each do |name, path|
        next if required.include?(name)
        next if required.any? { |kept| descendant?(modules.fetch(kept), path) }

        remove_tree(path)
      end
      required.to_a
    end

    def module_directories(root)
      Dir[File.join(root, "**", "qmldir")].each_with_object({}) do |path, modules|
        module_name = File.foreach(path).filter_map { |line| line[/^\s*module\s+(\S+)/, 1] }.first
        modules[module_name] = File.dirname(path) if module_name
      end
    end

    def module_imports(directory, modules)
      imports = Set.new
      qmldir = File.join(directory, "qmldir")
      File.foreach(qmldir) do |line|
        dependency = line[/^\s*(?:depends|import)\s+([A-Za-z][A-Za-z0-9_.]*)\b/, 1]
        imports << dependency if dependency
      end
      nested = modules.values.reject { |candidate| candidate == directory }
                      .select { |candidate| descendant?(candidate, directory) }
      qml_files = Dir[File.join(directory, "**", "*.qml")].reject do |path|
        nested.any? { |child| descendant?(path, child) }
      end
      imports.merge(qml_imports(qml_files))
      imports
    end

    def native_path_for(environment_name)
      manifest_path = File.join(@native, "client.json")
      return nil unless File.file?(manifest_path)

      manifest = JSON.parse(File.read(manifest_path))
      relative = Array(manifest.fetch("environment", {})[environment_name]).first
      return nil unless relative

      path = File.expand_path(relative, @native)
      unless path == @native || descendant?(path, @native)
        raise ArgumentError, "unsafe native client path while tree-shaking: #{relative.inspect}"
      end
      path
    end

    def prune_native_plugins(components, qml_modules)
      root = native_path_for("QT_PLUGIN_PATH")
      return unless root && File.directory?(root)

      explicit_plugins = resolve_explicit_plugins(root)
      has_text_input = !(components.to_set & TEXT_INPUT_COMPONENTS).empty?
      has_multimedia = qml_modules.include?("QtMultimedia")
      has_quick3d = qml_modules.any? { |name| name.start_with?("QtQuick3D") }

      prune_plugin_directory(root, "assetimporters", keep_all: has_quick3d, explicit_plugins:)
      prune_plugin_directory(root, "multimedia", keep_all: has_multimedia, explicit_plugins:)
      prune_plugin_directory(root, "imageformats", explicit_plugins:) do |path|
        feature = IMAGE_PLUGIN_FEATURES[plugin_identity(path)]
        feature && @qt_features.include?(feature)
      end
      prune_plugin_directory(root, "iconengines", explicit_plugins:) do |path|
        @qt_features.include?("svg-icons") && plugin_identity(path).include?("svg")
      end
      prune_plugin_directory(root, "networkinformation", explicit_plugins:) do |_path|
        @qt_features.include?("network-reachability")
      end
      tls_plugins = preferred_tls_plugins(File.join(root, "tls"))
      prune_plugin_directory(root, "tls", explicit_plugins:) do |path|
        @qt_features.include?("tls") && tls_plugins.include?(path)
      end
      prune_plugin_directory(root, "styles", explicit_plugins:)
      if qml_modules.include?("QtQuick.LocalStorage")
        prune_plugin_directory(root, "sqldrivers", explicit_plugins:) do |path|
          plugin_identity(path).include?("sqlite")
        end
      else
        prune_plugin_directory(root, "sqldrivers", explicit_plugins:)
      end
      remove_tree(File.join(root, "platformthemes")) if @platform.linux?
      remove_tree(File.join(root, "platforminputcontexts")) if @platform.linux? && !has_text_input
      remove_tree(File.join(root, "generic")) if @platform.linux?
      FileUtils.rm_f(File.join(root, "wayland-decoration-client", "libadwaita.so")) if @platform.linux?
      prune_linux_platform_plugins(root) if @platform.linux?
    end

    def detected_qt_features
      features = Set.new(@configuration.features)
      ruby_sources.each do |path|
        Ripper.lex(File.read(path)).each do |_position, event, token, _state|
          next unless event == :on_tstring_content

          token.scan(/\.([A-Za-z0-9]+)(?:\z|[?#])/).flatten.each do |extension|
            feature = IMAGE_FORMAT_FEATURES[extension.downcase]
            features << feature if feature
          end
          features << "tls" if token.match?(%r{(?:https|wss)://}i)
        end
      end
      features
    end

    def resolve_explicit_plugins(root)
      inventory = Dir[File.join(root, "*", "*")].select { |path| File.file?(path) }
      resolved = Set.new
      missing = []
      @configuration.plugins.each do |configured|
        category, requested = configured.split("/", 2)
        match = inventory.find do |path|
          File.basename(File.dirname(path)) == category && plugin_identity(path) == plugin_identity(requested)
        end
        match ? resolved << match : missing << configured
      end
      unless missing.empty?
        raise ArgumentError, "configured Qt plugin is unavailable: #{missing.join(', ')}"
      end
      resolved
    end

    def prune_plugin_directory(root, name, keep_all: false, explicit_plugins:)
      directory = File.join(root, name)
      return unless File.directory?(directory)

      Dir.children(directory).sort.each do |entry|
        path = File.join(directory, entry)
        keep = keep_all || explicit_plugins.include?(path) || (block_given? && yield(path))
        FileUtils.rm_f(path) if File.file?(path) && !keep
      end
      remove_tree(directory) if Dir.empty?(directory)
    end

    def plugin_identity(path)
      File.basename(path.to_s)
          .sub(/\.(?:dylib|dll|so(?:\..*)?)\z/i, "")
          .sub(/\Alib/, "")
          .downcase
    end

    def preferred_tls_plugins(directory)
      return Set.new unless File.directory?(directory)

      candidates = Dir[File.join(directory, "*")].select { |path| File.file?(path) }
      preferred = if @platform.macos?
                    "qsecuretransportbackend"
                  elsif @platform.windows?
                    "qschannelbackend"
                  else
                    "qopensslbackend"
                  end
      matches = candidates.select { |path| plugin_identity(path).include?(preferred) }
      Set.new(matches.empty? ? candidates : matches)
    end

    def retained_native_plugins
      root = native_path_for("QT_PLUGIN_PATH")
      return [] unless root && File.directory?(root)

      Dir[File.join(root, "*", "*")].select { |path| File.file?(path) }.map do |path|
        path.delete_prefix("#{root}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
      end.sort
    end

    def prune_linux_platform_plugins(plugin_root)
      platforms = File.join(plugin_root, "platforms")
      return unless File.directory?(platforms)

      keep = /\A(?:libqxcb|libqwayland(?:-[A-Za-z0-9_+-]+)?|libqoffscreen)\.so(?:\..*)?\z/
      Dir.children(platforms).each do |name|
        path = File.join(platforms, name)
        FileUtils.rm_f(path) if File.file?(path) && !name.match?(keep)
      end
    end

    def prune_translations
      candidates = [File.join(@native, "translations")]
      if @platform.macos?
        candidates << File.join(@native, "zui-host.app", "Contents", "Resources", "translations")
      end
      candidates.each { |path| remove_tree(path) }
    end

    def prune_native_libraries
      if @platform.linux?
        prune_linux_libraries
      elsif @platform.macos?
        prune_macos_frameworks
      elsif @platform.windows?
        prune_windows_libraries
      end
    end

    def prune_linux_libraries
      library_root = File.join(@native, "lib")
      return unless File.directory?(library_root)

      available = Dir.children(library_root).to_h { |name| [name, File.join(library_root, name)] }
      roots = native_binary_roots(["*.so", "*.so.*"])
      closure = Set.new
      queue = roots.dup
      inspected = Set.new
      successful = false
      begin
        until queue.empty?
          binary = queue.shift
          next unless File.file?(binary) && inspected.add?(binary)

          result = Command.run(["ldd", binary], env: { "LD_LIBRARY_PATH" => library_root },
                               timeout: 30, max_output_bytes: 2_000_000)
          next unless result.success?

          successful = true
          result.stdout.each_line do |line|
            name = line[/^\s*(\S+)\s+=>/, 1]
            path = line[/=>\s+(\/\S+)/, 1] || line[/^\s*(\/\S+)/, 1]
            name ||= File.basename(path) if path
            next unless name && available.key?(name) && closure.add?(name)

            queue << available.fetch(name)
          end
        end
      rescue Errno::ENOENT, CommandTimeout, CommandOutputLimit
        @warnings << "native Linux library analysis was unavailable; libraries were retained"
        return
      end
      return unless successful

      available.each do |name, path|
        FileUtils.rm_f(path) unless closure.include?(name) || name.start_with?(".")
      end
    end

    def prune_macos_frameworks
      root = File.join(@native, "zui-host.app", "Contents", "Frameworks")
      return unless File.directory?(root)

      available = Dir[File.join(root, "*.framework")].to_h { |path| [File.basename(path), path] }
      dylibs = Dir[File.join(root, "*.dylib")].to_h { |path| [File.basename(path), path] }
      roots = native_binary_roots(["*.dylib", "*.so"])
      queue = roots.dup
      required = Set.new
      required_dylibs = Set.new
      inspected = Set.new
      successful = false
      begin
        until queue.empty?
          binary = queue.shift
          next unless File.file?(binary) && inspected.add?(binary)

          result = Command.run(["otool", "-L", binary], timeout: 30, max_output_bytes: 2_000_000)
          next unless result.success?

          successful = true
          result.stdout.scan(%r{([^/\s]+\.framework)/}).flatten.each do |name|
            next unless available.key?(name) && required.add?(name)

            framework_binary = canonical_framework_binary(available.fetch(name), name.delete_suffix(".framework"))
            queue << framework_binary if framework_binary
          end
          result.stdout.each_line do |line|
            dependency = line.strip.split(/\s+\(/, 2).first
            name = File.basename(dependency.to_s)
            next unless dylibs.key?(name) && required_dylibs.add?(name)

            queue << dylibs.fetch(name)
          end
        end
      rescue Errno::ENOENT, CommandTimeout, CommandOutputLimit
        @warnings << "native macOS framework analysis was unavailable; frameworks were retained"
        return
      end
      return unless successful

      available.each { |name, path| remove_tree(path) unless required.include?(name) }
      dylibs.each { |name, path| FileUtils.rm_f(path) unless required_dylibs.include?(name) }
    end

    def canonical_framework_binary(framework, name)
      Dir[File.join(framework, "**", name)].find { |path| File.file?(path) }
    end

    def prune_windows_libraries
      bin = File.join(@native, "bin")
      return unless File.directory?(bin)

      available = Dir[File.join(bin, "*.dll")].to_h { |path| [File.basename(path).downcase, path] }
      queue = native_binary_roots(["*.dll"])
      required = Set.new
      inspected = Set.new
      parsed = false
      until queue.empty?
        binary = queue.shift
        next unless File.file?(binary) && inspected.add?(binary)

        dependencies = PEDependencies.imports(binary)
        next unless dependencies

        parsed = true
        dependencies.each do |name|
          key = name.downcase
          next unless available.key?(key) && required.add?(key)

          queue << available.fetch(key)
        end
      end
      unless parsed
        @warnings << "native Windows library analysis was unavailable; libraries were retained"
        return
      end

      available.each { |name, path| FileUtils.rm_f(path) unless required.include?(name) }
    end

    def native_binary_roots(patterns)
      manifest = JSON.parse(File.read(File.join(@native, "client.json")))
      roots = [File.join(@native, manifest.fetch("executable"))]
      [native_path_for("QML_IMPORT_PATH"), native_path_for("QT_PLUGIN_PATH")].compact.each do |root|
        patterns.each { |pattern| roots.concat(Dir[File.join(root, "**", pattern)]) }
      end
      roots.uniq
    end

    def update_client_manifest(components, qml_modules)
      path = File.join(@native, "client.json")
      return unless File.file?(path)

      manifest = JSON.parse(File.read(path))
      manifest["tree_shaken"] = true
      manifest["components"] = components.map(&:to_s).sort
      manifest["qml_modules"] = qml_modules.sort
      manifest["qt_style"] = @configuration.style
      manifest["qt_features"] = @qt_features.to_a.sort
      manifest["qt_plugins"] = retained_native_plugins
      File.write(path, "#{JSON.pretty_generate(manifest)}\n")
    end

    def descendant?(path, parent)
      path.start_with?("#{parent}#{File::SEPARATOR}")
    end

    def remove_tree(path)
      FileUtils.remove_entry(path) if File.exist?(path) || File.symlink?(path)
    end

    def tree_bytes(root)
      Dir[File.join(root, "**", "*")].sum { |path| File.file?(path) ? File.size(path) : 0 }
    end
  end
end
