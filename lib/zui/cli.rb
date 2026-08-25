# frozen_string_literal: true

require "json"
require "rbconfig"

module Zui
  class CLI
    USAGE = "Usage: zui <new NAME|configure|doctor [--fix]|run FILE|bundle [--dist] [--no-tree-shake] [DIRECTORY]|version>"

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
      source = File.expand_path(arguments.shift || Dir.pwd)
      raise ArgumentError, "bundle accepts one directory" unless arguments.empty?

      if create_installers
        raise ArgumentError, "--name cannot be used with --dist; set name in config.rb" if name

        packager = DistPackager.new(tree_shake:)
        paths = packager.package(source, output: destination)
        paths.each { |path| @out.puts("Created distribution artifact #{path}") }
        report_tree_shaking(packager.tree_shake_report)
        return 0
      end

      distribution = Distribution.new(tree_shake:)
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
      if client.configured?
        report_ready(client)
        0
      elsif fix
        @out.puts("Repair: downloading the verified native client from GitHub Releases...")
        client.configure!
        report_ready(client)
        0
      else
        @out.puts("Client: not configured")
        @out.puts("Run `zui doctor --fix` to install the native client and bundle support.")
        1
      end
    end

    def configure(arguments)
      raise ArgumentError, "configure accepts no arguments" unless arguments.empty?
      platform = Platform.current.assert_supported!
      client = Client.new(platform:)
      @out.puts("Configuring Zui #{VERSION} for #{platform.id}...")
      client.configure!
      report_ready(client)
      0
    end

    def report_ready(client)
      @out.puts("Client: #{client.root}")
      @out.puts("Run: ready")
      @out.puts("Bundle: ready")
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
