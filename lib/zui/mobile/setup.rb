# frozen_string_literal: true

require "fileutils"
require "json"
require "rbconfig"

module Zui
  module Mobile
    class Setup
      QT_VERSION = "6.8.3"
      NDK_VERSION = "27.0.12077973"
      BUILD_TOOLS_VERSION = "35.0.1"
      MRUBY_REVISION = "831da26b9021de0369d17b71b5667e2941a1a32d"
      MRUBY_JSON_REVISION = "f99d9428025469f2400f93c53b185f65f963e507"
      PROJECT_TEMPLATE_ROOT = File.expand_path("templates", __dir__)

      attr_reader :config_path

      def initialize(config_path: nil, framework_root: FRAMEWORK_ROOT, environment: ENV,
                     host_platform: Platform.current, command: Command, out: $stdout)
        @environment = environment
        @framework_root = File.expand_path(framework_root)
        @host_platform = host_platform
        @command = command
        @out = out
        @root = File.expand_path(environment["ZUI_MOBILE_HOME"] || File.join(Dir.home, ".zui", "mobile"))
        @config_path = File.expand_path(config_path || environment["ZUI_MOBILE_CONFIG"] || File.join(@root, "config.json"))
      end

      def enabled?
        read_config["enabled"] == true
      end

      def enable!
        config = read_config.merge("enabled" => true, "version" => 1)
        write_config(config)
        config
      end

      def prepare_project!(project)
        project = File.expand_path(project)
        raise ArgumentError, "mobile project directory not found: #{project}" unless File.directory?(project)

        %w[main.rb config.rb].each do |file|
          path = File.join(project, file)
          raise ArgumentError, "mobile project is missing #{file}: #{project}" unless File.file?(path)
        end

        %w[android ios].each do |platform|
          copy_project_template(platform, File.join(project, platform))
        end
        %w[android ios].map { |platform| File.join(project, platform) }
      end

      def fix!
        enable!
        dependencies = detect_dependencies
        repair_sources!(dependencies)
        dependencies = detect_dependencies
        repair_qt!(dependencies)
        dependencies = detect_dependencies
        repair_android_packages!(dependencies)
        dependencies = detect_dependencies
        missing = required_keys.reject { |key| present?(dependencies[key]) }
        unless missing.empty?
          labels = missing.map { |key| dependency_label(key) }.join(", ")
          raise ArgumentError, "mobile setup could not find #{labels}; install the platform SDK and rerun `zui mobile --fix`"
        end

        config = read_config.merge("enabled" => true, "version" => 1).merge(dependencies)
        write_config(config)
        config
      end

      def dependencies(target)
        raise ArgumentError, "mobile support is disabled; run `zui mobile --enable` first" unless enabled?

        values = detect_dependencies.merge(read_config) do |key, detected, configured|
          configured?(key, configured) ? configured : detected
        end
        keys = target.to_sym == :ios ? ios_keys : android_keys
        missing = keys.reject { |key| present?(values[key]) }
        unless missing.empty?
          labels = missing.map { |key| dependency_label(key) }.join(", ")
          raise ArgumentError, "mobile setup needs #{labels}; run `zui mobile --fix`"
        end
        values
      end

      def summary(config = read_config)
        lines = ["Mobile support: #{config['enabled'] ? 'enabled' : 'disabled'}"]
        %w[qt_host qt_ios qt_android mruby_root mruby_json android_sdk android_ndk].each do |key|
          lines << "#{dependency_label(key)}: #{config[key] || 'not configured'}"
        end
        lines
      end

      private

      def copy_project_template(platform, destination)
        source = File.join(PROJECT_TEMPLATE_ROOT, platform)
        raise ArgumentError, "Zui mobile #{platform} template is missing: #{source}" unless File.directory?(source)

        Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH).sort.each do |template|
          relative = template.delete_prefix("#{source}#{File::SEPARATOR}")
          next if relative.empty? || %w[. ..].include?(relative)

          target = File.join(destination, relative)
          if File.directory?(template)
            FileUtils.mkdir_p(target)
          elsif !File.exist?(target)
            FileUtils.mkdir_p(File.dirname(target))
            FileUtils.cp(template, target)
          end
        end
      end

      def read_config
        return {} unless File.file?(@config_path)

        JSON.parse(File.read(@config_path))
      rescue JSON::ParserError => error
        raise ArgumentError, "invalid mobile setup file #{@config_path}: #{error.message}"
      end

      def write_config(config)
        FileUtils.mkdir_p(File.dirname(@config_path))
        temporary = "#{@config_path}.tmp-#{Process.pid}"
        File.write(temporary, "#{JSON.pretty_generate(config)}\n")
        File.rename(temporary, @config_path)
      ensure
        FileUtils.rm_f(temporary) if defined?(temporary)
      end

      def detect_dependencies
        qt_roots = [
          @environment["ZUI_QT_ROOT"], File.join(@framework_root, "tmp", "Qt"),
          File.join(Dir.home, "Qt"), File.join(@root, "Qt")
        ].compact
        qt_host_name = @host_platform.macos? ? "macos" : (@host_platform.windows? ? "msvc2022_64" : "gcc_64")
        android_sdk = first_directory(
          @environment["ANDROID_SDK_ROOT"], @environment["ANDROID_HOME"],
          File.join(Dir.home, "Library", "Android", "sdk"), File.join(Dir.home, "Android", "Sdk")
        )
        {
          "qt_host" => first_directory(@environment["ZUI_QT_HOST"], *qt_roots.map { |root| File.join(root, QT_VERSION, qt_host_name) }),
          "qt_ios" => first_directory(@environment["ZUI_QT_IOS"], *qt_roots.map { |root| File.join(root, QT_VERSION, "ios") }),
          "qt_android" => first_directory(@environment["ZUI_QT_ANDROID"], *qt_roots.map { |root| File.join(root, QT_VERSION, "android_arm64_v8a") }),
          "mruby_root" => first_directory(@environment["ZUI_MRUBY_ROOT"], File.join(@framework_root, "tmp", "mobile-deps", "mruby"), File.join(@root, "src", "mruby")),
          "mruby_json" => first_directory(@environment["ZUI_MRUBY_JSON"], File.join(@framework_root, "tmp", "mobile-deps", "mruby-json"), File.join(@root, "src", "mruby-json")),
          "android_sdk" => android_sdk,
          "android_ndk" => first_directory(@environment["ANDROID_NDK_ROOT"], @environment["ANDROID_NDK_HOME"], android_sdk && File.join(android_sdk, "ndk", NDK_VERSION)),
          "apple_team" => @environment["ZUI_APPLE_TEAM"]
        }.compact
      end

      def first_directory(*paths)
        path = paths.compact.find { |candidate| !candidate.empty? && File.directory?(File.expand_path(candidate)) }
        path && File.expand_path(path)
      end

      def present?(value)
        value.is_a?(String) && !value.empty? && File.directory?(value)
      end

      def configured?(key, value)
        return value.is_a?(String) && !value.empty? if key == "apple_team"

        present?(value)
      end

      def required_keys
        keys = android_keys
        keys += ios_keys if @host_platform.macos?
        keys.uniq
      end

      def ios_keys
        %w[qt_host qt_ios mruby_root mruby_json]
      end

      def android_keys
        %w[qt_host qt_android mruby_root mruby_json android_sdk android_ndk]
      end

      def dependency_label(key)
        {
          "qt_host" => "Qt host SDK", "qt_ios" => "Qt iOS SDK", "qt_android" => "Qt Android SDK",
          "mruby_root" => "mruby", "mruby_json" => "mruby-json", "android_sdk" => "Android SDK",
          "android_ndk" => "Android NDK", "apple_team" => "Apple team"
        }.fetch(key.to_s, key.to_s)
      end

      def repair_sources!(dependencies)
        source_root = File.join(@root, "src")
        unless present?(dependencies["mruby_root"])
          clone_source("https://github.com/mruby/mruby.git", MRUBY_REVISION, File.join(source_root, "mruby"))
        end
        unless present?(dependencies["mruby_json"])
          clone_source("https://github.com/mattn/mruby-json.git", MRUBY_JSON_REVISION, File.join(source_root, "mruby-json"))
        end
      end

      def clone_source(repository, revision, destination)
        FileUtils.mkdir_p(File.dirname(destination))
        run!(["git", "clone", "--filter=blob:none", repository, destination],
             label: "downloading #{File.basename(destination)}", timeout: 600)
        run!(["git", "checkout", revision], chdir: destination,
             label: "pinning #{File.basename(destination)}", timeout: 120)
      end

      def repair_qt!(dependencies)
        missing = %w[qt_host qt_android]
        missing << "qt_ios" if @host_platform.macos?
        return if missing.all? { |key| present?(dependencies[key]) }

        python = @environment["PYTHON"] || "python3"
        tools = File.join(@root, "tools")
        aqt = File.join(tools, @host_platform.windows? ? "Scripts" : "bin", executable_name("aqt"))
        unless File.executable?(aqt)
          run!([python, "-m", "venv", tools], label: "creating the mobile setup environment", timeout: 180)
          pip = File.join(tools, @host_platform.windows? ? "Scripts" : "bin", executable_name("pip"))
          run!([pip, "install", "aqtinstall==3.3.0"], label: "installing the Qt downloader", timeout: 600)
        end
        qt_root = File.join(@root, "Qt")
        host = @host_platform.macos? ? %w[mac desktop clang_64] : %w[linux desktop gcc_64]
        run!([aqt, "install-qt", host[0], host[1], QT_VERSION, host[2], "-O", qt_root],
             label: "installing the Qt host SDK", timeout: 1_800) unless present?(dependencies["qt_host"])
        if @host_platform.macos? && !present?(dependencies["qt_ios"])
          run!([aqt, "install-qt", "mac", "ios", QT_VERSION, "ios", "-O", qt_root],
               label: "installing the Qt iOS SDK", timeout: 1_800)
        end
        unless present?(dependencies["qt_android"])
          run!([aqt, "install-qt", "all_os", "android", QT_VERSION, "android_arm64_v8a", "-O", qt_root],
               label: "installing the Qt Android SDK", timeout: 1_800)
        end
      end

      def repair_android_packages!(dependencies)
        sdk = dependencies["android_sdk"]
        return unless present?(sdk)

        manager = File.join(sdk, "cmdline-tools", "latest", "bin", executable_name("sdkmanager"))
        return unless File.executable?(manager)
        required = [
          File.join(sdk, "platform-tools"), File.join(sdk, "build-tools", BUILD_TOOLS_VERSION),
          File.join(sdk, "platforms", "android-35"), File.join(sdk, "ndk", NDK_VERSION)
        ]
        return if required.all? { |path| File.directory?(path) }

        run!([manager, "platform-tools", "platforms;android-35", "build-tools;#{BUILD_TOOLS_VERSION}",
              "ndk;#{NDK_VERSION}", "cmake;3.22.1"], label: "installing Android build packages", timeout: 1_800)
      end

      def executable_name(name)
        @host_platform.windows? ? "#{name}.exe" : name
      end

      def run!(arguments, label:, chdir: nil, timeout:)
        @out.puts("#{label.capitalize}...")
        result = @command.run(arguments, chdir:, timeout:, max_output_bytes: 32_000_000)
        return result if result.success?

        details = [result.stdout, result.stderr].join("\n").strip
        details = details.byteslice(-8_000, 8_000) if details.bytesize > 8_000
        raise ArgumentError, "#{label} failed#{details.empty? ? '' : ":\n#{details}"}"
      end
    end
  end
end
