# frozen_string_literal: true

require "fileutils"
require "digest"
require "json"
require "rbconfig"
require "set"

module Zui
  module Mobile
    Result = Struct.new(:app, :apk, :bundle_id, :simulator, :device, :pid, keyword_init: true)

    def self.copy_project_assets(project:, stage:, excluding: [])
      source = File.join(project, "assets")
      return unless File.directory?(source)

      excluded = Array(excluding).compact.map { |path| File.realpath(path) }.to_set
      destination = File.join(stage, "assets")
      Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH).sort.each do |path|
        next unless File.file?(path)
        resolved = File.realpath(path)
        next if File.basename(path) == ".DS_Store" || excluded.include?(resolved)

        unless resolved.start_with?("#{File.realpath(source)}#{File::SEPARATOR}")
          raise ArgumentError, "mobile asset symlink escapes the project: #{path}"
        end
        relative = path.delete_prefix("#{source}#{File::SEPARATOR}")
        target = File.join(destination, relative)
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(path, target, preserve: true)
      end
    end

    def self.configured_release_assets(project:, config:)
      (config.icons.values + config.splashes.values).uniq.filter_map do |relative|
        path = File.expand_path(relative, project)
        path if File.file?(path)
      end
    end

    class IOSBuilder
      DEFAULT_DEPLOYMENT_TARGET = "16.0"
      DEFAULT_ARCHITECTURE = "x86_64"
      RUNTIME_MODES = %i[lite full].freeze
      BUILTIN_CRUBY_GEMS = %w[bundler json zui].freeze
      IOS_PLATFORM = Platform.new(os: :ios, arch: :arm64).freeze

      def initialize(project:, qt_ios: nil, qt_host: nil, mruby_root: nil, mruby_json: nil,
                     cruby_source_root: nil, cruby_build_root: nil, runtime_mode: :lite,
                     output: nil, simulator: nil, device: nil, team: nil,
                     architecture: DEFAULT_ARCHITECTURE,
                     deployment_target: DEFAULT_DEPLOYMENT_TARGET, framework_root: FRAMEWORK_ROOT,
                     environment: ENV, host_platform: Platform.current, command: Command,
                     gem_spec_loader: nil, out: $stdout)
        @project = File.expand_path(project)
        @qt_ios = expand_dependency(qt_ios || environment["ZUI_QT_IOS"])
        @qt_host = expand_dependency(qt_host || environment["ZUI_QT_HOST"])
        @mruby_root = expand_dependency(mruby_root || environment["ZUI_MRUBY_ROOT"])
        @mruby_json = expand_dependency(mruby_json || environment["ZUI_MRUBY_JSON"])
        @cruby_source_root = expand_dependency(cruby_source_root || environment["ZUI_CRUBY_SOURCE_ROOT"])
        @cruby_build_root = expand_dependency(cruby_build_root || environment["ZUI_CRUBY_BUILD_ROOT"])
        @runtime_mode = runtime_mode.to_sym
        @requested_simulator = simulator
        @device = (device == true || device == :auto) ? "auto" : device&.to_s
        @team = team || environment["ZUI_APPLE_TEAM"]
        default_output = File.join(@project, "dist", physical_device? ? "ios-device" : "ios-simulator")
        @output = File.expand_path(output || default_output)
        @architecture = physical_device? ? "arm64" : architecture.to_s
        @deployment_target = deployment_target.to_s
        @framework_root = File.expand_path(framework_root)
        @host_platform = host_platform
        @command = command
        @gem_spec_loader = gem_spec_loader || LockedGems.new(environment:).method(:specs)
        @out = out
      end

      def build(install: true)
        validate!
        config = Dist.load(project: @project, platform: IOS_PLATFORM)
        stage = prepare_stage(config)
        sdk_name = physical_device? ? "iphoneos" : "iphonesimulator"
        sdk_label = physical_device? ? "iPhone" : "iOS Simulator"
        sdk = command_output(["xcrun", "--sdk", sdk_name, "--show-sdk-path"],
                             label: "locating the #{sdk_label} SDK")
        runtime_target = physical_device? ? "device" : "simulator"
        build_name = "zui-ios-#{runtime_target}-#{@architecture}-bytecode"
        if full_runtime?
          copy_cruby_support(stage)
        else
          build_mruby(sdk, build_name, platform: runtime_target)
          compile_application(stage)
        end
        xcode_project = configure_xcode(config, stage, build_name, sdk:)
        destination = physical_device? ? select_physical_device(xcode_project) : select_simulator(xcode_project)
        build_xcode(xcode_project, destination)
        products = physical_device? ? "Release-iphoneos" : "Release-iphonesimulator"
        app = File.join(@output, "xcode", products, "#{config.name}.app")
        raise ArgumentError, "iOS build did not produce #{app}" unless File.directory?(app)

        result = Result.new(app:, bundle_id: config.identifier,
                            simulator: physical_device? ? nil : destination,
                            device: physical_device? ? destination : nil)
        return result unless install

        install_and_launch(app, config.identifier, destination)
      end

      private

      def expand_dependency(path)
        path && !path.empty? ? File.expand_path(path) : nil
      end

      def physical_device?
        @device && !@device.empty?
      end

      def full_runtime?
        @runtime_mode == :full
      end

      def validate!
        unless @host_platform.macos?
          raise ArgumentError, "iOS applications must be built on macOS with Xcode"
        end
        raise ArgumentError, "mobile project directory not found: #{@project}" unless File.directory?(@project)
        raise ArgumentError, "mobile project is missing main.rb" unless File.file?(File.join(@project, "main.rb"))
        validate_directory!(@qt_ios, "Qt iOS SDK", "--qt-ios or ZUI_QT_IOS")
        validate_directory!(@qt_host, "Qt host SDK", "--qt-host or ZUI_QT_HOST")
        validate_file!(File.join(@qt_ios, "bin", "qt-cmake"), "Qt iOS qt-cmake")
        unless RUNTIME_MODES.include?(@runtime_mode)
          raise ArgumentError, "unsupported iOS Ruby runtime: #{@runtime_mode}"
        end
        if full_runtime?
          validate_cruby!
        else
          validate_directory!(@mruby_root, "mruby source", "--mruby or ZUI_MRUBY_ROOT")
          validate_directory!(@mruby_json, "mruby-json source", "--mruby-json or ZUI_MRUBY_JSON")
          validate_file!(File.join(@mruby_root, "minirake"), "mruby minirake")
          validate_file!(File.join(@mruby_json, "mrbgem.rake"), "mruby-json gem")
        end
        if physical_device? && @requested_simulator
          raise ArgumentError, "choose either --device or --simulator, not both"
        end
        if physical_device? && (!@team || @team.empty?)
          raise ArgumentError, "physical iPhone builds require --team or ZUI_APPLE_TEAM"
        end
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
        raise ArgumentError, "#{name} not found: #{path}" unless path && File.file?(path)
      end

      def validate_cruby!
        validate_directory!(@cruby_source_root, "CRuby source", "--cruby-source or ZUI_CRUBY_SOURCE_ROOT")
        validate_directory!(@cruby_build_root, "CRuby iOS build", "--cruby-build or ZUI_CRUBY_BUILD_ROOT")
        validate_file!(File.join(@cruby_source_root, "include", "ruby.h"), "CRuby embedding header")
        validate_file!(cruby_library, "CRuby static library")
        validate_file!(File.join(@cruby_build_root, "ext", "json", "generator", "generator.a"),
                       "CRuby static JSON generator")
        validate_file!(File.join(@cruby_build_root, "ext", "json", "parser", "parser.a"),
                       "CRuby static JSON parser")
        validate_file!(File.join(@cruby_build_root, "enc", "libenc.a"), "CRuby static encodings")
        cruby_standard_extension_libraries.each do |path|
          validate_file!(path, "CRuby static standard extension")
        end
        validate_directory!(File.join(@cruby_source_root, "lib"), "CRuby standard library", "CRuby source lib")
        validate_directory!(File.join(@cruby_build_root, ".ext", "common"),
                            "generated CRuby standard library", "CRuby build .ext/common")
        validate_file!(File.join(@cruby_build_root, "rbconfig.rb"), "target CRuby rbconfig")
        cruby_json_sources.each_value { |path| validate_file!(path, "CRuby JSON support") }
      end

      def cruby_library
        return unless @cruby_build_root

        Dir[File.join(@cruby_build_root, "libruby.*-static.a")].sort.first
      end

      def cruby_json_sources
        common = File.join(@cruby_build_root.to_s, ".ext", "common", "json")
        {
          "version.rb" => File.join(common, "version.rb"),
          "common.rb" => File.join(common, "common.rb"),
          "ext.rb" => File.join(common, "ext.rb"),
          File.join("ext", "generator", "state.rb") => File.join(common, "ext", "generator", "state.rb")
        }
      end

      def cruby_standard_extension_libraries
        %w[
          continuation/continuation.a coverage/coverage.a date/date_core.a digest/digest.a
          etc/etc.a fcntl/fcntl.a io/nonblock/nonblock.a io/wait/wait.a monitor/monitor.a
          objspace/objspace.a rbconfig/sizeof/sizeof.a stringio/stringio.a strscan/strscan.a
        ].map { |relative| File.join(@cruby_build_root.to_s, "ext", relative) }
      end

      def prepare_stage(config)
        stage = File.join(@output, "stage")
        FileUtils.rm_rf(stage)
        FileUtils.mkdir_p(stage)
        source = LiteSource.new(project: @project, allow_external_requires: full_runtime?).call
        File.binwrite(File.join(stage, "app.rb"), source)
        copy_assets(stage, config)
        create_icon_catalog(stage, config.icon_path(@project, IOS_PLATFORM))
        create_splash_screen(stage, config.splash_path(@project, IOS_PLATFORM))
        stage
      end

      def copy_assets(stage, config)
        Mobile.copy_project_assets(
          project: @project, stage:,
          excluding: Mobile.configured_release_assets(project: @project, config:)
        )
      end

      def copy_cruby_support(stage)
        destination = File.join(stage, "cruby", "json")
        cruby_json_sources.each do |relative, source|
          target = File.join(destination, relative)
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp(source, target)
        end
        copy_cruby_standard_library(stage)
        gems = copy_project_gems(stage)
        @out.puts("Bundling the embedded CRuby runtime with #{gems.size} locked project gems...")
      end

      def copy_cruby_standard_library(stage)
        destination = File.join(stage, "cruby", "stdlib")
        copy_directory_contents(File.join(@cruby_source_root, "lib"), File.join(destination, "source"))
        generated = File.join(destination, "generated")
        copy_directory_contents(File.join(@cruby_build_root, ".ext", "common"), generated)
        cruby_json_sources.each_key do |relative|
          FileUtils.rm_f(File.join(generated, "json", relative))
        end
        FileUtils.cp(File.join(@cruby_build_root, "rbconfig.rb"), File.join(generated, "rbconfig.rb"))
      end

      def copy_directory_contents(source, destination)
        FileUtils.mkdir_p(destination)
        entries = Dir.children(source)
        FileUtils.cp_r(entries.map { |entry| File.join(source, entry) }, destination) unless entries.empty?
      end

      def copy_project_gems(stage)
        specs = @gem_spec_loader.call(@project).reject do |spec|
          BUILTIN_CRUBY_GEMS.include?(spec.name) ||
            (spec.respond_to?(:default_gem?) && spec.default_gem?)
        end
        names = Set.new
        destination = File.join(stage, "cruby", "gems")
        specifications = File.join(stage, "cruby", "specifications")
        FileUtils.mkdir_p([destination, specifications])
        manifest_gems = specs.sort_by(&:full_name).map do |spec|
          validate_mobile_gem!(spec, names)
          target = File.join(destination, spec.full_name)
          files = packaged_mobile_gem_files(spec)
          install_mobile_gem_files(spec, target, files)
          File.write(File.join(specifications, "#{spec.full_name}.gemspec"), spec.to_ruby(files:))
          require_paths = mobile_gem_require_paths(spec)
          {
            "name" => spec.name,
            "version" => spec.version.to_s,
            "full_name" => spec.full_name,
            "require_paths" => require_paths,
            "load_paths" => require_paths.map { |path| File.join("gems", spec.full_name, path) }
          }
        end
        manifest = {
          "format" => 1,
          "standard_library_paths" => %w[stdlib/generated stdlib/source],
          "gems" => manifest_gems
        }
        manifest["digest"] = mobile_gem_digest(File.join(stage, "cruby"), manifest)
        File.write(File.join(stage, "cruby", "gems.json"), "#{JSON.pretty_generate(manifest)}\n")
        specs
      end

      def validate_mobile_gem!(spec, names)
        unless names.add?(spec.name)
          raise ArgumentError, "duplicate bundled iOS gem: #{spec.name}"
        end
        unless spec.full_name.match?(/\A[A-Za-z0-9_.-]+\z/)
          raise ArgumentError, "unsafe bundled iOS gem name: #{spec.full_name.inspect}"
        end
        unless File.directory?(spec.full_gem_path)
          raise ArgumentError, "project gem is not installed: #{spec.full_name}; run `bundle install`"
        end
        platform = spec.platform.to_s
        unless platform == "ruby"
          raise ArgumentError,
                "iOS --full cannot bundle platform gem #{spec.full_name} (#{platform}); " \
                "use a pure-Ruby release or provide an iOS static extension"
        end
        extensions = Array(spec.extensions).reject(&:empty?)
        native_files = Dir[File.join(spec.full_gem_path, "**", "*.{bundle,so,dylib}")]
        return if extensions.empty? && native_files.empty?

        details = extensions.empty? ? native_files.map { |path| File.basename(path) } : extensions
        raise ArgumentError,
              "iOS --full cannot dynamically load native gem #{spec.full_name} " \
              "(#{details.join(', ')}); provide an iOS static extension integration"
      end

      def mobile_gem_require_paths(spec)
        paths = Array(spec.require_paths)
        paths = ["lib"] if paths.empty?
        paths.map do |path|
          relative = path.to_s
          expanded = File.expand_path(relative, spec.full_gem_path)
          root = File.expand_path(spec.full_gem_path)
          unless expanded == root || expanded.start_with?("#{root}#{File::SEPARATOR}")
            raise ArgumentError, "gem #{spec.full_name} has an unsafe require path: #{relative.inspect}"
          end
          relative
        end
      end

      def packaged_mobile_gem_files(spec)
        files = Array(spec.files).map(&:to_s).reject(&:empty?).uniq.sort
        if files.empty?
          raise ArgumentError, "gem #{spec.full_name} has no packaged files; set spec.files in its gemspec"
        end
        files
      end

      def install_mobile_gem_files(spec, target, files)
        root = File.realpath(spec.full_gem_path)
        files.each do |relative|
          source = File.expand_path(relative, root)
          unless source.start_with?("#{root}#{File::SEPARATOR}") && File.file?(source)
            raise ArgumentError, "gem #{spec.full_name} has an unsafe or missing packaged file: #{relative.inspect}"
          end
          unless File.realpath(source).start_with?("#{root}#{File::SEPARATOR}")
            raise ArgumentError, "gem #{spec.full_name} has a packaged symlink outside its root: #{relative.inspect}"
          end
          destination = File.join(target, relative)
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(source, destination, preserve: true)
        end
      end

      def mobile_gem_digest(root, manifest)
        digest = Digest::SHA256.new
        digest << JSON.generate(manifest)
        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).sort.each do |path|
          next unless File.file?(path)

          digest << path.delete_prefix("#{root}#{File::SEPARATOR}") << "\0"
          digest << Digest::SHA256.file(path).digest
        end
        digest.hexdigest
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

      def create_splash_screen(stage, splash)
        return unless splash

        directory = File.join(stage, "Assets.xcassets", "ZuiSplash.imageset")
        FileUtils.mkdir_p(directory)
        FileUtils.cp(splash, File.join(directory, "ZuiSplash.png"))
        manifest = {
          "images" => [{ "filename" => "ZuiSplash.png", "idiom" => "universal", "scale" => "1x" }],
          "info" => { "author" => "zui", "version" => 1 }
        }
        File.write(File.join(directory, "Contents.json"), "#{JSON.pretty_generate(manifest)}\n")
        File.write(File.join(stage, "LaunchScreen.storyboard"), <<~XML)
          <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" targetRuntime="iOS.CocoaTouch" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="zui-launch-controller">
              <dependencies>
                  <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="23506"/>
                  <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
              </dependencies>
              <scenes>
                  <scene sceneID="zui-launch-scene">
                      <objects>
                          <viewController id="zui-launch-controller" sceneMemberID="viewController">
                              <view key="view" contentMode="scaleToFill" id="zui-launch-view">
                                  <rect key="frame" x="0.0" y="0.0" width="390" height="844"/>
                                  <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                                  <subviews>
                                      <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFill" image="ZuiSplash" translatesAutoresizingMaskIntoConstraints="NO" id="zui-splash-image">
                                          <rect key="frame" x="0.0" y="0.0" width="390" height="844"/>
                                      </imageView>
                                  </subviews>
                                  <color key="backgroundColor" red="0.02745098039" green="0.06666666667" blue="0.05098039216" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                                  <constraints>
                                      <constraint firstItem="zui-splash-image" firstAttribute="leading" secondItem="zui-launch-view" secondAttribute="leading" id="zui-splash-leading"/>
                                      <constraint firstAttribute="trailing" secondItem="zui-splash-image" secondAttribute="trailing" id="zui-splash-trailing"/>
                                      <constraint firstItem="zui-splash-image" firstAttribute="top" secondItem="zui-launch-view" secondAttribute="top" id="zui-splash-top"/>
                                      <constraint firstAttribute="bottom" secondItem="zui-splash-image" secondAttribute="bottom" id="zui-splash-bottom"/>
                                  </constraints>
                              </view>
                          </viewController>
                          <placeholder placeholderIdentifier="IBFirstResponder" id="zui-launch-responder" sceneMemberID="firstResponder"/>
                      </objects>
                  </scene>
              </scenes>
              <resources><image name="ZuiSplash" width="1024" height="1024"/></resources>
          </document>
        XML
      end

      def build_mruby(sdk, build_name, platform: "simulator")
        library = File.join(@mruby_root, "build", build_name, "lib", "libmruby.a")
        compiler = File.join(@mruby_root, "build", "host", "bin", "mrbc")
        if File.file?(library) && File.executable?(compiler)
          @out.puts("Mobile Ruby runtime: ready")
          return
        end

        @out.puts("Building the embedded Ruby runtime for #{platform == 'device' ? 'iPhone' : 'the iOS Simulator'}...")
        configuration = File.join(@framework_root, "runtime", "mruby", "ios_simulator_build_config.rb")
        validate_file!(configuration, "Zui iOS mruby build configuration")
        run!([RbConfig.ruby, "minirake"], label: "building mruby", chdir: @mruby_root,
             env: {
               "MRUBY_CONFIG" => configuration,
               "ZUI_IOS_SDK" => sdk,
               "ZUI_IOS_ARCH" => @architecture,
               "ZUI_IOS_PLATFORM" => platform,
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

      def configure_xcode(config, stage, build_name, sdk:)
        build = File.join(@output, "xcode")
        FileUtils.mkdir_p(build)
        @out.puts("Generating the native iOS application...")
        arguments = [
          File.join(@qt_ios, "bin", "qt-cmake"), "-S", File.join(@framework_root, "native"),
          "-B", build, "-G", "Xcode", "-DQT_HOST_PATH=#{@qt_host}",
          "-DCMAKE_OSX_SYSROOT=#{sdk}", "-DCMAKE_OSX_ARCHITECTURES=#{@architecture}",
          "-DCMAKE_OSX_DEPLOYMENT_TARGET=#{@deployment_target}", "-DZUI_EMBEDDED_RUNTIME=ON",
          "-DZUI_MOBILE_APP_DIR=#{stage}", "-DZUI_MOBILE_APP_NAME=#{config.name}",
          "-DZUI_MOBILE_BUNDLE_ID=#{config.identifier}", "-DZUI_MOBILE_APP_VERSION=#{config.version}",
          "-DZUI_MOBILE_BUILD_VERSION=1"
        ]
        if full_runtime?
          arguments.concat([
            "-DZUI_EMBEDDED_CRUBY=ON", "-DZUI_CRUBY_SOURCE_ROOT=#{@cruby_source_root}",
            "-DZUI_CRUBY_BUILD_ROOT=#{@cruby_build_root}", "-DZUI_CRUBY_LIBRARY=#{cruby_library}"
          ])
        else
          arguments.concat(["-DZUI_MRUBY_ROOT=#{@mruby_root}", "-DZUI_MRUBY_BUILD=#{build_name}"])
        end
        custom_launch_screen = File.join(stage, "LaunchScreen.storyboard")
        project_launch_screen = File.join(@project, "ios", "LaunchScreen.storyboard")
        launch_screen = if File.file?(project_launch_screen)
                          project_launch_screen
                        elsif File.file?(custom_launch_screen)
                          custom_launch_screen
                        else
                          File.join(@framework_root, "native", "LaunchScreen.storyboard")
                        end
        arguments << "-DZUI_IOS_LAUNCH_SCREEN=#{launch_screen}"
        info_plist = File.join(@project, "ios", "Info.plist.in")
        entitlements = File.join(@project, "ios", "Zui.entitlements")
        ios_project = File.join(@project, "ios")
        arguments << "-DZUI_IOS_INFO_PLIST=#{info_plist}" if File.file?(info_plist)
        arguments << "-DZUI_IOS_ENTITLEMENTS=#{entitlements}" if File.file?(entitlements)
        arguments << "-DZUI_IOS_PROJECT_DIR=#{ios_project}" if File.directory?(ios_project)
        run!(arguments, label: "generating the Xcode project", timeout: 240)
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

      def select_physical_device(xcode_project)
        return @device unless @device == "auto"

        destinations = command_output([
          "xcodebuild", "-project", xcode_project, "-scheme", "zui-host", "-showdestinations"
        ], label: "finding connected physical iPhones", timeout: 120)
        devices = destinations.scan(/\{\s*platform:iOS,\s*arch:[^,}]+,\s*id:([^,}\s]+),\s*name:([^}]+)\}/)
        device = devices.find { |identifier, _name| !identifier.include?("placeholder") }
        unless device
          raise ArgumentError, "no physical iPhone is connected; unlock it, trust this Mac, and enable Developer Mode"
        end

        @out.puts("Using physical iPhone #{device.last.strip} (#{device.first})")
        device.first
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

      def build_xcode(xcode_project, destination)
        @out.puts("Building for the #{physical_device? ? 'physical iPhone' : 'iOS Simulator'}...")
        arguments = [
          "xcodebuild", "-project", xcode_project, "-scheme", "zui-host", "-configuration", "Release",
          "-sdk", physical_device? ? "iphoneos" : "iphonesimulator",
          "-destination", "platform=iOS#{physical_device? ? '' : ' Simulator'},id=#{destination}"
        ]
        if physical_device?
          arguments.concat([
            "-allowProvisioningUpdates", "-allowProvisioningDeviceRegistration",
            "DEVELOPMENT_TEAM=#{@team}", "CODE_SIGN_STYLE=Automatic"
          ])
        else
          arguments << "CODE_SIGNING_ALLOWED=NO"
        end
        arguments << "build"
        run!(arguments, label: "building the iOS application", timeout: 1_800,
             max_output_bytes: 64_000_000)
      end

      def install_and_launch(app, bundle_id, destination)
        if physical_device?
          @out.puts("Installing and launching on the physical iPhone...")
          run!(["xcrun", "devicectl", "device", "install", "app", "--device", destination, app],
               label: "installing the iPhone application", timeout: 240)
          output = command_output([
            "xcrun", "devicectl", "device", "process", "launch", "--device", destination,
            "--terminate-existing", bundle_id
          ], label: "launching the iPhone application", timeout: 120)
          pid = output[/process identifier (\d+)/i, 1]&.to_i
          pid ||= wait_for_physical_pid(destination, app)
          raise ArgumentError, "iPhone application exited during launch" unless pid

          return Result.new(app:, bundle_id:, device: destination, pid:)
        end

        @out.puts("Installing and launching on the iOS Simulator...")
        run!(["xcrun", "simctl", "install", destination, app],
             label: "installing the iOS application", timeout: 180)
        output = command_output(["xcrun", "simctl", "launch", destination, bundle_id],
                                label: "launching the iOS application", timeout: 120)
        pid = output[/:\s*(\d+)/, 1]&.to_i
        Result.new(app:, bundle_id:, simulator: destination, pid:)
      end

      def wait_for_physical_pid(device, app)
        bundle_name = File.basename(app)
        executable = File.basename(app, ".app")
        pattern = /^\s*(\d+)\s+.*\/#{Regexp.escape(bundle_name)}\/#{Regexp.escape(executable)}(?:\s|$)/
        20.times do
          result = @command.run([
            "xcrun", "devicectl", "device", "info", "processes", "--device", device
          ], timeout: 30, max_output_bytes: 16_000_000)
          pid = result.stdout[pattern, 1]&.to_i if result.success?
          return pid if pid && pid.positive?

          sleep(0.25)
        end
        nil
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

require_relative "mobile/setup"
require_relative "mobile/android_builder"
