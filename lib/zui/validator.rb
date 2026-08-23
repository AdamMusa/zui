# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "timeout"

module Zui
  class Validator
    Result = Struct.new(:valid, :errors, :surfaces, keyword_init: true) do
      def valid? = valid
    end

    def initialize(framework_root: FRAMEWORK_ROOT, ruby: RbConfig.ruby)
      @framework_root = framework_root
      @ruby = ruby
    end

    def validate(path)
      project = File.directory?(path) ? File.expand_path(path) : File.dirname(File.expand_path(path))
      program = File.directory?(path) ? File.join(project, "main.rb") : File.expand_path(path)
      errors = []
      errors << "main.rb not found: #{program}" unless File.file?(program)
      return Result.new(valid: false, errors:, surfaces: []) unless errors.empty?

      syntax = Command.run([@ruby, "-c", program], timeout: 15)
      errors << syntax.stderr.strip unless syntax.success?
      return Result.new(valid: false, errors:, surfaces: []) unless errors.empty?

      output, runtime_errors, status = execute_probe(program, project)
      messages = output.lines.filter_map do |line|
        JSON.parse(line)
      rescue JSON::ParserError
        nil
      end
      render = messages.find { |message| message["type"] == "render" }
      ready = messages.any? { |message| message["type"] == "ready" }
      errors << "application did not emit a ready message" unless ready
      errors << "application did not emit a render tree" unless render
      errors << runtime_errors.strip unless status.success? || runtime_errors.strip.empty?
      errors.compact!
      errors.reject!(&:empty?)
      Result.new(valid: errors.empty?, errors:, surfaces: render ? render.fetch("surfaces", {}).keys : [])
    rescue CommandTimeout => error
      Result.new(valid: false, errors: [error.message], surfaces: [])
    end

    private

    def execute_probe(program, project)
      Open3.popen3({ "ZUI_PROJECT_DIR" => project }, @ruby, "-I", File.join(@framework_root, "lib"), program) do |stdin, stdout, stderr, wait|
        stdin.close
        output_reader = Thread.new { stdout.read }
        error_reader = Thread.new { stderr.read }
        status = Timeout.timeout(15) { wait.value }
        return [output_reader.value, error_reader.value, status]
      rescue Timeout::Error
        Process.kill("TERM", wait.pid)
        raise CommandTimeout, "application validation timed out after 15 seconds"
      end
    end
  end
end
