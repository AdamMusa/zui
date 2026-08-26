# frozen_string_literal: true

require "fileutils"
require "json"
require "rbconfig"

module Zui
  module Mobile
    Result = Struct.new(:app, :bundle_id, :simulator, :pid, keyword_init: true)

    class IOSBuilder
      DEFAULT_DEPLOYMENT_TARGET = "16.0"
      DEFAULT_ARCHITECTURE = "x86_64"
      IOS_PLATFORM = Platform.new(os: :ios, arch: :arm64).freeze

      def initialize(project:, qt_ios: nil, qt_host: nil, mruby_root: nil, mruby_json: nil,
                     output: nil, simulator: nil, architecture: DEFAULT_ARCHITECTURE,
                     deployment_target: DEFAULT_DEPLOYMENT_TARGET, framework_root: FRAMEWORK_ROOT,
                     environment: ENV, host_platform: Platform.current, command: Command, out: $stdout)
        @project = File.expand_path(project)
        @qt_ios = expand_dependency(qt_ios || environment["ZUI_QT_IOS"])
        @qt_host = expand_dependency(qt_host || environment["ZUI_QT_HOST"])
        @mruby_root = expand_dependency(mruby_root || environment["ZUI_MRUBY_ROOT"])
        @mruby_json = expand_dependency(mruby_json || environment["ZUI_MRUBY_JSON"])
        @output = File.expand_path(output || File.join(@project, "dist", "ios-simulator"))
        @requested_simulator = simulator
        @architecture = architecture.to_s
        @deployment_target = deployment_target.to_s
        @framework_root = File.expand_path(framework_root)
        @host_platform = host_platform
        @command = command
        @out = out
      end

      def build(install: true)
        validate!
        config = Dist.load(project: @project, platform: IOS_PLATFORM)
        stage = prepare_stage(config)
        sdk = command_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"],
                             label: "locating the iOS Simulator SDK")
        build_name = "zui-ios-simulator-#{@architecture}-bytecode"
        build_mruby(sdk, build_name)
        compile_application(stage)
        xcode_project = configure_xcode(config, stage, build_name)
        simulator = select_simulator(xcode_project)
        build_xcode(xcode_project, simulator)
        app = File.join(@output, "xcode", "Release-iphonesimulator", "#{config.name}.app")
        raise ArgumentError, "iOS build did not produce #{app}" unless File.directory?(app)

        return Result.new(app:, bundle_id: config.identifier, simulator:) unless install

        install_and_launch(app, config.identifier, simulator)
      end

      private

      def expand_dependency(path)
        path && !path.empty? ? File.expand_path(path) : nil
      end

      def validate!
        unless @host_platform.macos?
          raise ArgumentError, "iOS applications must be built on macOS with Xcode"
        end
        raise ArgumentError, "mobile project directory not found: #{@project}" unless File.directory?(@project)
        raise ArgumentError, "mobile project is missing main.rb" unless File.file?(File.join(@project, "main.rb"))
        validate_directory!(@qt_ios, "Qt iOS SDK", "--qt-ios or ZUI_QT_IOS")
        validate_directory!(@qt_host, "Qt host SDK", "--qt-host or ZUI_QT_HOST")
        validate_directory!(@mruby_root, "mruby source", "--mruby or ZUI_MRUBY_ROOT")
        validate_directory!(@mruby_json, "mruby-json source", "--mruby-json or ZUI_MRUBY_JSON")
        validate_file!(File.join(@qt_ios, "bin", "qt-cmake"), "Qt iOS qt-cmake")
        validate_file!(File.join(@mruby_root, "minirake"), "mruby minirake")
        validate_file!(File.join(@mruby_json, "mrbgem.rake"), "mruby-json gem")
        unless %w[x86_64 arm64].include?(@architecture)
          raise ArgumentError, "iOS Simulator architecture must be x86_64 or arm64"
        end
        unless @deployment_target.match?(/\A\d+(?:\.\d+){1,2}\z/)
          raise ArgumentError, "iOS deployment target must look like 16.0"
        end
      end

      def validate_directory!(path, name, option)
        return if path && File.directory?(path)

        raise ArgumentError, "#{name} not found; set #{option}"
      end

      def validate_file!(path, name)
        raise ArgumentError, "#{name} not found: #{path}" unless File.file?(path)
      end

      def prepare_stage(config)
        stage = File.join(@output, "stage")
        FileUtils.mkdir_p(stage)
        File.binwrite(File.join(stage, "app.rb"), LiteSource.new(project: @project).call)
        copy_assets(stage)
        create_icon_catalog(stage, config.icon_path(@project, IOS_PLATFORM))
        stage
      end

      def copy_assets(stage)
        source = File.join(@project, "assets")
        return unless File.directory?(source)

        destination = File.join(stage, "assets")
        FileUtils.mkdir_p(destination)
        entries = Dir.children(source)
        FileUtils.cp_r(entries.map { |entry| File.join(source, entry) }, destination) unless entries.empty?
      end

      def create_icon_catalog(stage, icon)
        directory = File.join(stage, "Assets.xcassets", "AppIcon.appiconset")
        FileUtils.mkdir_p(directory)
        FileUtils.cp(icon, File.join(directory, "AppIcon.png"))
        manifest = {
          "images" => [{
            "filename" => "AppIcon.png", "idiom" => "universal", "platform" => "ios", "size" => "1024x1024"
          }],
          "info" => { "author" => "zui", "version" => 1 }
        }
        File.write(File.join(directory, "Contents.json"), "#{JSON.pretty_generate(manifest)}\n")
      end

      def build_mruby(sdk, build_name)
        library = File.join(@mruby_root, "build", build_name, "lib", "libmruby.a")
        compiler = File.join(@mruby_root, "build", "host", "bin", "mrbc")
        if File.file?(library) && File.executable?(compiler)
          @out.puts("Mobile Ruby runtime: ready")
          return
        end

        @out.puts("Building the embedded Ruby runtime for the iOS Simulator...")
        configuration = File.join(@framework_root, "runtime", "mruby", "ios_simulator_build_config.rb")
        validate_file!(configuration, "Zui iOS mruby build configuration")
        run!([RbConfig.ruby, "minirake"], label: "building mruby", chdir: @mruby_root,
             env: {
               "MRUBY_CONFIG" => configuration,
               "ZUI_IOS_SIMULATOR_SDK" => sdk,
               "ZUI_IOS_SIMULATOR_ARCH" => @architecture,
               "ZUI_IOS_DEPLOYMENT_TARGET" => @deployment_target,
               "ZUI_MRUBY_BUILD" => build_name,
               "ZUI_MRUBY_JSON" => @mruby_json
             }, timeout: 900)
        raise ArgumentError, "mruby build did not produce #{library}" unless File.file?(library)
        raise ArgumentError, "mruby build did not produce #{compiler}" unless File.executable?(compiler)
      end

      def compile_application(stage)
        source = File.join(stage, "app.rb")
        bytecode = File.join(stage, "app.mrb")
        compiler = File.join(@mruby_root, "build", "host", "bin", "mrbc")
        @out.puts("Precompiling the mobile Ruby application...")
        run!([compiler, "-o#{bytecode}", source], label: "precompiling the Ruby application", timeout: 120)
        raise ArgumentError, "mrbc did not produce #{bytecode}" unless File.file?(bytecode)
      end

      def configure_xcode(config, stage, build_name)
        build = File.join(@output, "xcode")
        FileUtils.mkdir_p(build)
        @out.puts("Generating the native iOS application...")
        run!([
          File.join(@qt_ios, "bin", "qt-cmake"), "-S", File.join(@framework_root, "native"),
          "-B", build, "-G", "Xcode", "-DQT_HOST_PATH=#{@qt_host}",
          "-DCMAKE_OSX_DEPLOYMENT_TARGET=#{@deployment_target}", "-DZUI_EMBEDDED_RUNTIME=ON",
          "-DZUI_MRUBY_ROOT=#{@mruby_root}", "-DZUI_MRUBY_BUILD=#{build_name}",
          "-DZUI_MOBILE_APP_DIR=#{stage}", "-DZUI_MOBILE_APP_NAME=#{config.name}",
          "-DZUI_MOBILE_BUNDLE_ID=#{config.identifier}", "-DZUI_MOBILE_APP_VERSION=#{config.version}",
          "-DZUI_MOBILE_BUILD_VERSION=1"
        ], label: "generating the Xcode project", timeout: 240)
        project = File.join(build, "zui-host.xcodeproj")
        raise ArgumentError, "Qt did not generate #{project}" unless File.directory?(project)

        project
      end

      def select_simulator(xcode_project)
        eligible = compatible_simulators(xcode_project)
        if eligible.empty? || (@requested_simulator && !eligible.include?(@requested_simulator))
          eligible = compatible_simulators(xcode_project)
        end
        if @requested_simulator
          unless eligible.include?(@requested_simulator)
            raise ArgumentError, "requested simulator is not compatible with this Qt iOS SDK: #{@requested_simulator}"
          end
          ensure_booted(@requested_simulator)
          return @requested_simulator
        end

        devices = JSON.parse(command_output(["xcrun", "simctl", "list", "devices", "-j"],
                                            label: "listing iOS Simulators"))
        all = devices.fetch("devices").values.flatten
        booted = all.find { |device| device["state"] == "Booted" && eligible.include?(device["udid"]) }
        return booted.fetch("udid") if booted

        available = all.find { |device| device.fetch("isAvailable", true) && eligible.include?(device["udid"]) }
        raise ArgumentError, "no iOS Simulator compatible with this Qt iOS SDK is installed" unless available

        ensure_booted(available.fetch("udid"))
        available.fetch("udid")
      rescue JSON::ParserError, KeyError => error
        raise ArgumentError, "could not read the installed iOS Simulators: #{error.message}"
      end

      def compatible_simulators(xcode_project)
        destinations = command_output([
          "xcodebuild", "-project", xcode_project, "-scheme", "zui-host", "-showdestinations"
        ], label: "finding compatible iOS Simulators", timeout: 120)
        destinations.scan(/platform:iOS Simulator[^}]*id:([^,}\s]+)/).flatten
      end

      def ensure_booted(simulator)
        result = @command.run(["xcrun", "simctl", "boot", simulator], timeout: 120,
                              max_output_bytes: 8_000_000)
        unless result.success? || result.stderr.include?("current state: Booted")
          raise_command_error("booting the iOS Simulator", result)
        end
        run!(["xcrun", "simctl", "bootstatus", simulator, "-b"],
             label: "waiting for the iOS Simulator", timeout: 180)
      end

      def build_xcode(xcode_project, simulator)
        @out.puts("Building for the iOS Simulator...")
        run!([
          "xcodebuild", "-project", xcode_project, "-scheme", "zui-host", "-configuration", "Release",
          "-sdk", "iphonesimulator", "-destination", "platform=iOS Simulator,id=#{simulator}",
          "CODE_SIGNING_ALLOWED=NO", "build"
        ], label: "building the iOS application", timeout: 1_800, max_output_bytes: 64_000_000)
      end

      def install_and_launch(app, bundle_id, simulator)
        @out.puts("Installing and launching on the iOS Simulator...")
        run!(["xcrun", "simctl", "install", simulator, app], label: "installing the iOS application", timeout: 180)
        output = command_output(["xcrun", "simctl", "launch", simulator, bundle_id],
                                label: "launching the iOS application", timeout: 120)
        pid = output[/:\s*(\d+)/, 1]&.to_i
        Result.new(app:, bundle_id:, simulator:, pid:)
      end

      def command_output(arguments, label:, timeout: 60)
        result = @command.run(arguments, timeout:, max_output_bytes: 16_000_000)
        raise_command_error(label, result) unless result.success?

        result.stdout.strip
      end

      def run!(arguments, label:, chdir: nil, env: {}, timeout:, max_output_bytes: 32_000_000)
        result = @command.run(arguments, chdir:, env:, timeout:, max_output_bytes:)
        raise_command_error(label, result) unless result.success?

        result
      end

      def raise_command_error(label, result)
        details = [result.stdout, result.stderr].join("\n").strip
        details = details.byteslice(-8_000, 8_000) if details.bytesize > 8_000
        raise ArgumentError, "#{label} failed#{details.empty? ? '' : ":\n#{details}"}"
      end
    end
  end
end
