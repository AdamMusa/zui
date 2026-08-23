# frozen_string_literal: true

module Zui
  class SourceBundle
    REQUIRE_RELATIVE = /\A\s*require_relative\s*(?:\(\s*)?["']([^"']+)["']\s*\)?\s*(?:#.*)?\z/

    def initialize(entrypoint, root: File.dirname(entrypoint), embedded_frameworks: ["zui"])
      @entrypoint = File.expand_path(entrypoint)
      @root = File.expand_path(root)
      frameworks = Array(embedded_frameworks).map(&:to_s)
      raise ArgumentError, "embedded framework names cannot be empty" if frameworks.any?(&:empty?)

      names = frameworks.map { |name| Regexp.escape(name) }.join("|")
      @embedded_framework_require = /\A\s*require\s*(?:\(\s*)?["'](?:#{names})["']\s*\)?\s*(?:#.*)?\z/
      @loaded = {}
      @loading = []
    end

    def call
      expand(@entrypoint)
    end

    private

    def expand(path)
      path = ruby_path(File.expand_path(path))
      ensure_inside_root!(path)
      return "" if @loaded[path]
      raise ArgumentError, "circular require_relative: #{relative(path)}" if @loading.include?(path)
      raise ArgumentError, "required Ruby file not found: #{relative(path)}" unless File.file?(path)

      @loading << path
      source = File.readlines(path, chomp: true).map do |line|
        match = REQUIRE_RELATIVE.match(line)
        if match
          expand(File.expand_path(match[1], File.dirname(path)))
        elsif @embedded_framework_require.match?(line)
          ""
        else
          line
        end
      end.join("\n")
      @loaded[path] = true
      "# source: #{relative(path)}\n#{source}\n"
    ensure
      @loading.pop if @loading.last == path
    end

    def ruby_path(path)
      File.extname(path).empty? ? "#{path}.rb" : path
    end

    def ensure_inside_root!(path)
      return if path == @root || path.start_with?("#{@root}#{File::SEPARATOR}")

      raise ArgumentError, "require_relative escapes the application directory: #{path}"
    end

    def relative(path)
      path.delete_prefix("#{@root}#{File::SEPARATOR}")
    end
  end
end
