# frozen_string_literal: true

require "rbconfig"

module Zui
  class Runner
    def initialize(host: Host.new, framework_root: FRAMEWORK_ROOT, ruby: RbConfig.ruby)
      @host = host
      @framework_root = framework_root
      @ruby = ruby
    end

    def run(file, name: nil, environment: ENV.to_h)
      program = File.expand_path(file)
      raise ArgumentError, "Ruby file not found: #{program}" unless File.file?(program)
      executable = @host.executable
      project = File.dirname(program)
      arguments = [
        executable,
        "--qml-root", @framework_root,
        "--project", project,
        "--program", program,
        "--ruby", @ruby,
        "--load-path", File.join(@framework_root, "lib"),
        "--name", name || project_name(project)
      ]
      system(environment, *arguments)
      $?&.exitstatus || 1
    end

    private

    def project_name(path)
      File.basename(path).split(/[-_]/).map(&:capitalize).join(" ")
    end
  end
end
