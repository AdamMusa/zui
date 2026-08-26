# frozen_string_literal: true

module Zui
  class LiteSource
    RUNTIME_FILES = %w[
      lite_support.rb protocol.rb value.rb state_store.rb node.rb animation.rb scheduler.rb
      component_registry.rb components.rb builder.rb application.rb lite_entry.rb
    ].freeze
    REQUIRE = /^\s*require\s*(?:\(\s*)?["']([^"']+)["']/

    def initialize(project:, framework_root: FRAMEWORK_ROOT, allow_external_requires: false)
      @project = File.expand_path(project)
      @framework_root = File.expand_path(framework_root)
      @allow_external_requires = allow_external_requires == true
    end

    def call
      application = SourceBundle.new(
        File.join(@project, "main.rb"), root: @project, embedded_frameworks: ["zui"]
      ).call
      external = application.scan(REQUIRE).flatten.uniq
      unless @allow_external_requires || external.empty?
        raise ArgumentError,
              "--lite does not support CRuby gem requires (#{external.join(', ')}); use --full"
      end

      runtime = RUNTIME_FILES.map do |name|
        path = File.join(@framework_root, "lib", "zui", name)
        raise ArgumentError, "lite runtime source is missing: #{path}" unless File.file?(path)

        source = File.readlines(path).reject { |line| REQUIRE.match?(line) }.join
        "# runtime: #{name}\n#{source}"
      end
      runtime << "module Zui\n  VERSION = #{VERSION.dump}\nend"
      runtime << application
      "#{runtime.join("\n\n")}\n"
    end
  end
end
