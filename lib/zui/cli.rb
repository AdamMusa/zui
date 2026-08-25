# frozen_string_literal: true

require "json"
require "rbconfig"

module Zui
  class CLI
    USAGE = "Usage: zui <new NAME|configure|doctor [--fix]|run FILE|bundle [--dist] [--lite|--full] [--no-tree-shake] [DIRECTORY]|version>"

    def self.run(arguments, out: $stdout, err: $stderr)
      new(out:, err:).run(arguments.dup)
    end

    def initialize(out:, err:)
      @out = out
      @err = err
    end

    def run(arguments)
      command = arguments.shift
      case command
      when "new" then new_project(arguments)
      when "configure" then configure(arguments)
      when "run" then run_file(arguments)
      when "bundle" then bundle_project(arguments)
      when "doctor" then doctor(arguments)
      when "version", "--version", "-v" then @out.puts(VERSION); 0
      else
        @err.puts(USAGE)
        command.nil? ? 0 : 64
      end
    rescue Interrupt
      130
    rescue ArgumentError, SystemCallError, JSON::ParserError => error
      @err.puts("zui: #{error.message}")
      1
    end

    private

    def new_project(arguments)
      name = arguments.shift || raise(ArgumentError, "new requires a project name")
      raise ArgumentError, "new accepts only a project name" unless arguments.empty?
      destination = File.expand_path(slug(name))
      Generator.new(path: destination, name:).create
      @out.puts("Created Zui application in #{destination}")
      0
    end

    def run_file(arguments)
      file = File.expand_path(arguments.shift || raise(ArgumentError, "run requires a Ruby file"))
      raise ArgumentError, "run accepts one Ruby file" unless arguments.empty?
      Runner.new.run(file)
    end

    def bundle_project(arguments)
      name = option_value(arguments, "--name")
      destination = option_value(arguments, "--output")
      create_installers = !arguments.delete("--dist").nil?
      tree_shake = arguments.delete("--no-tree-shake").nil?
      lite = !arguments.delete("--lite").nil?
      full = !arguments.delete("--full").nil?
      raise ArgumentError, "bundle accepts only one of --lite or --full" if lite && full
      runtime_mode = full ? :full : :lite
      source = File.expand_path(arguments.shift || Dir.pwd)
      raise ArgumentError, "bundle accepts one directory" unless arguments.empty?

      if create_installers
        raise ArgumentError, "--name cannot be used with --dist; set name in config.rb" if name

        packager = DistPackager.new(tree_shake:, runtime_mode:)
        paths = packager.package(source, output: destination)
        paths.each { |path| @out.puts("Created distribution artifact #{path}") }
        report_tree_shaking(packager.tree_shake_report)
        return 0
      end

      distribution = Distribution.new(tree_shake:, runtime_mode:)
      path = distribution.bundle(source, name:, destination:)
      @out.puts("Bundled #{Platform.current.os} application in #{path}")
      report_tree_shaking(distribution.tree_shake_report)
      0
    end

    def report_tree_shaking(report)
      return unless report

      @out.puts("Tree-shaken runtime: #{report.components.length} components, #{format_bytes(report.saved_bytes)} removed")
    end

    def doctor(arguments)
      fix = arguments.delete("--fix")
      raise ArgumentError, "doctor accepts only --fix" unless arguments.empty?
      platform = Platform.current
      @out.puts("Zui #{VERSION}")
      @out.puts("Platform: #{platform.id}#{platform.supported? ? '' : ' (unsupported)'}")
      @out.puts("Ruby: #{RbConfig.ruby} (#{RUBY_VERSION})")
      return 1 unless platform.supported?

      client = Client.new(platform:)
      lite_runtime = LiteRuntime.new(platform:)
      client_ready = client.configured?
      lite_ready = lite_runtime.configured?
      if client_ready && lite_ready
        report_ready(client, lite_runtime)
        0
      elsif fix
        unless client_ready
          @out.puts("Repair: downloading the verified native client from GitHub Releases...")
          client.configure!
        end
        unless lite_ready
          @out.puts("Repair: downloading the verified lite mruby runtime from GitHub Releases...")
          lite_runtime.configure!
        end
        report_ready(client, lite_runtime)
        0
      else
        @out.puts(client_ready ? "Client: #{client.root}" : "Client: not configured")
        @out.puts(lite_ready ? "Lite runtime: #{lite_runtime.root}" : "Lite runtime: not configured")
        @out.puts("Run `zui doctor --fix` to install the native client and lite bundle runtime.")
        1
      end
    end

    def configure(arguments)
      raise ArgumentError, "configure accepts no arguments" unless arguments.empty?
      platform = Platform.current.assert_supported!
      client = Client.new(platform:)
      lite_runtime = LiteRuntime.new(platform:)
      @out.puts("Configuring Zui #{VERSION} for #{platform.id}...")
      client.configure!
      lite_runtime.configure!
      report_ready(client, lite_runtime)
      0
    end

    def report_ready(client, lite_runtime)
      @out.puts("Client: #{client.root}")
      @out.puts("Lite runtime: #{lite_runtime.root}")
      @out.puts("Run: ready")
      @out.puts("Bundle --lite: ready")
      @out.puts("Bundle --full: ready (uses this Ruby and the project's locked gems)")
    end

    def option_value(arguments, name)
      index = arguments.index(name)
      return nil unless index
      raise ArgumentError, "#{name} requires a value" if index == arguments.length - 1
      arguments.delete_at(index)
      arguments.delete_at(index)
    end

    def slug(value)
      result = value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      raise ArgumentError, "name must contain letters or numbers" if result.empty?
      result
    end

    def format_bytes(bytes)
      units = %w[B KB MB GB]
      value = bytes.to_f
      unit = units.shift
      while value >= 1024 && !units.empty?
        value /= 1024
        unit = units.shift
      end
      value >= 10 || unit == "B" ? "#{value.round} #{unit}" : format("%.1f %s", value, unit)
    end
  end
end
