# frozen_string_literal: true

require "json"
require "optparse"
require "rbconfig"

module Zui
  class CLI
    class UsageError < ArgumentError; end

    COMMANDS = {
      "new" => "Create a new Zui application",
      "configure" => "Install the native client and lite runtime",
      "doctor" => "Check or repair the local Zui installation",
      "run" => "Run a Ruby application with the native client",
      "bundle" => "Build a standalone app or release installer",
      "version" => "Print the installed Zui version"
    }.freeze

    GENERAL_HELP = <<~HELP.freeze
      Zui #{VERSION} — native desktop applications in Ruby

      Usage:
        zui COMMAND [arguments] [options]

      Commands:
        new NAME       #{COMMANDS.fetch("new")}
        configure      #{COMMANDS.fetch("configure")}
        doctor         #{COMMANDS.fetch("doctor")}
        run FILE       #{COMMANDS.fetch("run")}
        bundle [DIR]   #{COMMANDS.fetch("bundle")}
        version        #{COMMANDS.fetch("version")}

      Global options:
        -h, --help     Show this help
        -v, --version  Print the installed Zui version

      Run `zui help COMMAND` or `zui COMMAND --help` for command details.
    HELP

    COMMAND_HELP = {
      "new" => <<~HELP,
        Create a new Zui application.

        Usage:
          zui new NAME

        NAME becomes both the project directory and display name. Underscores,
        hyphens, and spaces are normalized; `smart_home` becomes “Smart Home”.
        The project includes Ruby sources, distribution config, and release icons.

        Example:
          zui new smart_home
      HELP
      "configure" => <<~HELP,
        Install the verified native client and lite mruby runtime.

        Usage:
          zui configure

        Downloads the platform assets for this Zui version from GitHub Releases,
        verifies their checksums and manifests, and installs them in the user cache.

        Equivalent repair command:
          zui doctor --fix
      HELP
      "doctor" => <<~HELP,
        Check or repair the local Zui installation.

        Usage:
          zui doctor [options]

        Options:
          -f, --fix  Download, verify, and install missing platform assets

        Without --fix, doctor is read-only and exits nonzero when setup is incomplete.

        Examples:
          zui doctor
          zui doctor --fix
      HELP
      "run" => <<~HELP,
        Run a Ruby application with the private native client.

        Usage:
          zui run FILE

        FILE is the Ruby entry point for the application.

        Example:
          zui run main.rb
      HELP
      "bundle" => <<~HELP,
        Build a standalone application or platform release installer.

        Usage:
          zui bundle [DIRECTORY] [options]

        Options:
          -n, --name NAME       Override the app name for a non-distribution bundle
          -o, --output PATH     Set the bundle destination or distribution directory
              --lite            Embed the portable mruby runtime (default)
              --full            Embed private CRuby and the project's locked gems
              --dist            Build platform installers using config.rb
              --no-tree-shake   Keep the complete component and Qt feature catalog

        DIRECTORY defaults to the current directory. --lite and --full are mutually
        exclusive. --dist reads the app name and release metadata from config.rb.

        Examples:
          zui bundle
          zui bundle --full .
          zui bundle --name "Smart Home" --output dist/SmartHome.app
          zui bundle --dist --full .
      HELP
      "version" => <<~HELP
        Print the installed Zui version.

        Usage:
          zui version
          zui --version
          zui -v
      HELP
    }.freeze

    def self.run(arguments, out: $stdout, err: $stderr)
      new(out:, err:).run(arguments.dup)
    end

    def initialize(out:, err:)
      @out = out
      @err = err
    end

    def run(arguments)
      command = arguments.shift
      @active_command = command
      return show_general_help if command.nil? || %w[-h --help].include?(command)
      return show_command_help(arguments) if command == "help"
      return show_named_help(command) if COMMANDS.key?(command) && help_requested?(arguments)

      case command
      when "new" then new_project(arguments)
      when "configure" then configure(arguments)
      when "run" then run_file(arguments)
      when "bundle" then bundle_project(arguments)
      when "doctor" then doctor(arguments)
      when "version", "--version", "-v" then print_version(arguments)
      else unknown_command(command)
      end
    rescue Interrupt
      130
    rescue OptionParser::ParseError, UsageError => error
      @err.puts("zui: #{error.message}")
      @err.puts(help_hint)
      1
    rescue ArgumentError, SystemCallError, JSON::ParserError => error
      @err.puts("zui: #{error.message}")
      1
    end

    private

    def new_project(arguments)
      parse_no_options!(arguments)
      name = arguments.shift || raise(UsageError, "new requires a project name")
      raise UsageError, "new accepts only one project name" unless arguments.empty?

      destination = File.expand_path(slug(name))
      Generator.new(path: destination, name:).create
      @out.puts("Created Zui application in #{destination}")
      0
    end

    def run_file(arguments)
      parse_no_options!(arguments)
      file = File.expand_path(arguments.shift || raise(UsageError, "run requires a Ruby file"))
      raise UsageError, "run accepts only one Ruby file" unless arguments.empty?

      Runner.new.run(file)
    end

    def bundle_project(arguments)
      options = { tree_shake: true }
      parser = OptionParser.new do |option|
        option.on("-n NAME", "--name NAME") { |value| options[:name] = value }
        option.on("-o PATH", "--output PATH") { |value| options[:destination] = value }
        option.on("--lite") { options[:lite] = true }
        option.on("--full") { options[:full] = true }
        option.on("--dist") { options[:create_installers] = true }
        option.on("--no-tree-shake") { options[:tree_shake] = false }
      end
      parser.parse!(arguments)
      if options[:lite] && options[:full]
        raise UsageError, "bundle accepts only one of --lite or --full"
      end

      runtime_mode = options[:full] ? :full : :lite
      source = File.expand_path(arguments.shift || Dir.pwd)
      raise UsageError, "bundle accepts only one directory" unless arguments.empty?

      if options[:create_installers]
        if options[:name]
          raise UsageError, "--name cannot be used with --dist; set name in config.rb"
        end

        packager = DistPackager.new(tree_shake: options[:tree_shake], runtime_mode:)
        paths = packager.package(source, output: options[:destination])
        paths.each { |path| @out.puts("Created distribution artifact #{path}") }
        report_tree_shaking(packager.tree_shake_report)
        return 0
      end

      distribution = Distribution.new(tree_shake: options[:tree_shake], runtime_mode:)
      path = distribution.bundle(source, name: options[:name], destination: options[:destination])
      @out.puts("Bundled #{Platform.current.os} application in #{path}")
      report_tree_shaking(distribution.tree_shake_report)
      0
    end

    def report_tree_shaking(report)
      return unless report

      @out.puts("Tree-shaken runtime: #{report.components.length} components, #{format_bytes(report.saved_bytes)} removed")
    end

    def doctor(arguments)
      fix = false
      OptionParser.new { |option| option.on("-f", "--fix") { fix = true } }.parse!(arguments)
      raise UsageError, "doctor accepts no positional arguments" unless arguments.empty?

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
      parse_no_options!(arguments)
      raise UsageError, "configure accepts no arguments" unless arguments.empty?

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

    def show_general_help
      @out.puts(GENERAL_HELP)
      0
    end

    def show_command_help(arguments)
      return show_general_help if arguments.empty? || arguments == ["-h"] || arguments == ["--help"]
      raise UsageError, "help accepts only one command" unless arguments.length == 1

      show_named_help(arguments.first)
    end

    def show_named_help(command)
      help = COMMAND_HELP[command]
      return unknown_command(command) unless help

      @out.puts(help)
      0
    end

    def help_requested?(arguments)
      arguments.any? { |argument| %w[-h --help].include?(argument) }
    end

    def print_version(arguments)
      parse_no_options!(arguments)
      raise UsageError, "version accepts no arguments" unless arguments.empty?

      @out.puts(VERSION)
      0
    end

    def unknown_command(command)
      @err.puts("zui: unknown command #{command.inspect}")
      @err.puts("Run `zui --help` to see available commands.")
      64
    end

    def help_hint
      if COMMANDS.key?(@active_command)
        "Run `zui help #{@active_command}` for usage."
      else
        "Run `zui --help` to see available commands."
      end
    end

    def parse_no_options!(arguments)
      OptionParser.new.parse!(arguments)
    end

    def slug(value)
      result = value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|\z/, "")
      raise UsageError, "name must contain letters or numbers" if result.empty?

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
