# frozen_string_literal: true

require "fileutils"
require "ripper"
require "set"

module Zui
  class RubyRuntimeShaker
    EXCLUDED_SOURCE_DIRECTORIES = %w[
      .bundle .git .github .ruby-lsp android coverage dist ios log spec test tmp
    ].freeze
    NATIVE_EXTENSIONS = %w[.bundle .dll .so].freeze

    Requirement = Struct.new(:type, :feature, keyword_init: true)
    Analysis = Struct.new(:requirements, :dynamic_requires, :rubygems, keyword_init: true)
    Report = Struct.new(
      :features, :files, :before_bytes, :after_bytes, :warnings, :fallback,
      keyword_init: true
    ) do
      def saved_bytes = before_bytes - after_bytes
      def tree_shaken? = fallback.nil?

      def to_h
        {
          "features" => features,
          "files" => files,
          "before_bytes" => before_bytes,
          "after_bytes" => after_bytes,
          "saved_bytes" => saved_bytes,
          "warnings" => warnings,
          "fallback" => fallback
        }
      end
    end

    def initialize(project:, runtime:, load_paths:, configured_features: [])
      @project = File.expand_path(project)
      @runtime = File.expand_path(runtime)
      @load_paths = Array(load_paths).map { |path| File.expand_path(path, @runtime) }.uniq
      @configured_features = Array(configured_features).map(&:to_s).uniq.sort
    end

    def shake!
      before_bytes = tree_bytes(@runtime)
      warnings = []
      application_analysis = analyze_sources(application_sources)
      fallback = fallback_reason(application_analysis)
      if fallback
        warnings << fallback
        return Report.new(
          features: [], files: standard_library_files.length, before_bytes:, after_bytes: before_bytes,
          warnings: warnings.freeze, fallback:
        )
      end

      index = feature_index
      required = Set.new
      selected_features = Set.new
      queue = []
      preserve_encodings(required)
      application_analysis.requirements.reject { |requirement| requirement.type == :relative }.each do |requirement|
        path = resolve_index(index, requirement.feature)
        next unless path

        selected_features << normalize_feature(requirement.feature)
        queue << path
      end
      @configured_features.each do |feature|
        path = resolve_index(index, feature)
        raise ArgumentError, "configured Ruby standard library feature is unavailable: #{feature}" unless path

        selected_features << normalize_feature(feature)
        queue << path
      end

      until queue.empty?
        path = queue.shift
        next unless required.add?(path)
        next unless File.extname(path) == ".rb"

        analysis = analyze_file(path)
        unless analysis.dynamic_requires.empty?
          fallback = "dynamic standard-library require in #{relative_runtime_path(path)}"
          warnings << fallback
          return Report.new(
            features: [], files: standard_library_files.length, before_bytes:, after_bytes: before_bytes,
            warnings: warnings.freeze, fallback:
          )
        end
        analysis.requirements.each do |requirement|
          dependency = if requirement.type == :relative
                         resolve_relative(path, requirement.feature)
                       else
                         resolve_index(index, requirement.feature)
                       end
          next unless dependency

          selected_features << feature_name(dependency)
          queue << dependency
        end
      end

      prune_standard_library(required)
      after_bytes = tree_bytes(@runtime)
      Report.new(
        features: selected_features.to_a.sort,
        files: required.length,
        before_bytes:,
        after_bytes:,
        warnings: warnings.freeze,
        fallback: nil
      )
    end

    private

    def application_sources
      project = Dir.glob(File.join(@project, "**", "*.rb")).select do |path|
        relative = path.delete_prefix("#{@project}#{File::SEPARATOR}")
        first = relative.split(File::SEPARATOR).first
        !EXCLUDED_SOURCE_DIRECTORIES.include?(first) && relative != "config.rb"
      end
      gems = Dir.glob(File.join(@runtime, "gems", "gems", "*", "**", "*.rb"))
      (project + gems).uniq.sort
    end

    def analyze_sources(paths)
      paths.each_with_object(Analysis.new(requirements: [], dynamic_requires: [], rubygems: false)) do |path, result|
        analysis = analyze_file(path)
        result.requirements.concat(analysis.requirements)
        result.dynamic_requires.concat(analysis.dynamic_requires.map { |line| [path, line] })
        result.rubygems ||= analysis.rubygems
      end
    end

    def analyze_file(path)
      syntax = Ripper.sexp(File.read(path))
      raise ArgumentError, "cannot tree-shake Ruby file with syntax errors: #{path}" unless syntax

      analysis = Analysis.new(requirements: [], dynamic_requires: [], rubygems: false)
      walk_syntax(syntax, analysis)
      analysis
    end

    def walk_syntax(node, analysis)
      return unless node.is_a?(Array)

      analysis.rubygems = true if node.first == :@const && %w[Bundler Gem].include?(node[1])
      call = call_parts(node)
      if call
        name, arguments, line = call
        if %w[require require_relative].include?(name)
          feature = static_string(arguments.first)
          if feature
            analysis.requirements << Requirement.new(
              type: name == "require_relative" ? :relative : :require,
              feature:
            )
            analysis.rubygems = true if feature == "rubygems" || feature.start_with?("bundler")
          else
            analysis.dynamic_requires << line
          end
        elsif name == "autoload"
          feature = static_string(arguments[1])
          if feature
            analysis.requirements << Requirement.new(type: :require, feature:)
          else
            analysis.dynamic_requires << line
          end
        elsif name == "gem"
          analysis.rubygems = true
        end
      end
      node.each { |child| walk_syntax(child, analysis) if child.is_a?(Array) }
    end

    def call_parts(node)
      case node.first
      when :command
        [identifier_value(node[1]), argument_nodes(node[2]), token_line(node[1])]
      when :method_add_arg
        [call_name(node[1]), argument_nodes(node[2]), token_line(node[1])]
      when :command_call
        [identifier_value(node[3]), argument_nodes(node[4]), token_line(node[3])]
      end
    end

    def call_name(node)
      return unless node.is_a?(Array)
      return identifier_value(node[1]) if %i[fcall vcall].include?(node.first)
      return identifier_value(node[3]) if node.first == :call

      nil
    end

    def identifier_value(node)
      node.is_a?(Array) && node.first.to_s.start_with?("@") ? node[1].to_s : nil
    end

    def token_line(node)
      return 0 unless node.is_a?(Array)
      return node[2].first if node.first.to_s.start_with?("@") && node[2].is_a?(Array)

      node.filter_map { |child| token_line(child) if child.is_a?(Array) }.find(&:positive?) || 0
    end

    def argument_nodes(node)
      return [] unless node.is_a?(Array)
      return Array(node[1]) if node.first == :args_add_block

      node.each do |child|
        next unless child.is_a?(Array)

        arguments = argument_nodes(child)
        return arguments unless arguments.empty?
      end
      []
    end

    def static_string(node)
      return unless node.is_a?(Array) && node.first == :string_literal
      return if syntax_type?(node, :string_embexpr)

      string_parts(node).join
    end

    def syntax_type?(node, type)
      return false unless node.is_a?(Array)
      return true if node.first == type

      node.any? { |child| child.is_a?(Array) && syntax_type?(child, type) }
    end

    def string_parts(node, parts = [])
      return parts unless node.is_a?(Array)

      parts << node[1] if node.first == :@tstring_content && node[1].is_a?(String)
      node.each { |child| string_parts(child, parts) if child.is_a?(Array) }
      parts
    end

    def fallback_reason(analysis)
      unless analysis.dynamic_requires.empty?
        path, line = analysis.dynamic_requires.first
        return "dynamic require at #{path}:#{line}; preserving the complete CRuby standard library"
      end
      if analysis.rubygems
        return "RubyGems runtime APIs detected; preserving the complete CRuby standard library"
      end

      nil
    end

    def feature_index
      @load_paths.each_with_object({}) do |root, index|
        next unless File.directory?(root)

        Dir.glob(File.join(root, "**", "*")).sort.each do |path|
          next unless File.file?(path)
          next unless [".rb", *NATIVE_EXTENSIONS].include?(File.extname(path))

          relative = path.delete_prefix("#{root}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
          index[relative] ||= path
          index[normalize_feature(relative)] ||= path
        end
      end
    end

    def normalize_feature(feature)
      value = feature.to_s.tr(File::SEPARATOR, "/")
      extension = File.extname(value)
      [".rb", *NATIVE_EXTENSIONS].include?(extension) ? value.delete_suffix(extension) : value
    end

    def resolve_index(index, feature)
      value = feature.to_s.tr(File::SEPARATOR, "/")
      index[value] || index[normalize_feature(value)]
    end

    def resolve_relative(source, feature)
      base = File.expand_path(feature, File.dirname(source))
      candidates = [base]
      candidates.concat([".rb", *NATIVE_EXTENSIONS].map { |extension| "#{base}#{extension}" })
      candidates.find { |path| standard_library_path?(path) && File.file?(path) }
    end

    def preserve_encodings(required)
      @load_paths.each do |root|
        encodings = File.join(root, "enc")
        next unless File.directory?(encodings)

        Dir.glob(File.join(encodings, "**", "*")).sort.each do |path|
          required << path if File.file?(path)
        end
      end
    end

    def prune_standard_library(required)
      standard_library_files.each { |path| FileUtils.rm_f(path) unless required.include?(path) }
      standard_library_roots.each do |root|
        Dir.glob(File.join(root, "**", "*")).sort_by { |path| -path.count(File::SEPARATOR) }.each do |path|
          Dir.rmdir(path) if File.directory?(path) && Dir.empty?(path)
        end
      end
    end

    def standard_library_files
      @standard_library_files ||= standard_library_roots.flat_map do |root|
        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).select do |path|
          File.lstat(path).file?
        end
      end.uniq.sort
    end

    def standard_library_roots
      @standard_library_roots ||= @load_paths.reject do |candidate|
        @load_paths.any? { |other| candidate != other && candidate.start_with?("#{other}#{File::SEPARATOR}") }
      end
    end

    def standard_library_path?(path)
      @load_paths.any? { |root| path == root || path.start_with?("#{root}#{File::SEPARATOR}") }
    end

    def feature_name(path)
      root = @load_paths.select { |candidate| standard_library_path_with_root?(path, candidate) }
                        .max_by(&:length)
      return File.basename(path, File.extname(path)) unless root

      relative = path.delete_prefix("#{root}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
      normalize_feature(relative)
    end

    def standard_library_path_with_root?(path, root)
      path == root || path.start_with?("#{root}#{File::SEPARATOR}")
    end

    def relative_runtime_path(path)
      path.delete_prefix("#{@runtime}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
    end

    def tree_bytes(root)
      Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).sum do |path|
        File.lstat(path).file? ? File.size(path) : 0
      end
    end
  end
end
