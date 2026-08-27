# frozen_string_literal: true

require "cgi"
require "fileutils"
require "rbconfig"

module Zui
  module Mobile
    class AndroidBuilder
      DEFAULT_ABI = "arm64-v8a"
      DEFAULT_API = 28
      DEFAULT_TARGET_API = 35
      DEFAULT_NDK_VERSION = "27.0.12077973"
      DEFAULT_BUILD_TOOLS_VERSION = "35.0.1"
      DEFAULT_CMAKE_VERSION = "3.22.1"
      ANDROID_PLATFORM = Platform.new(os: :android, arch: :arm64).freeze

      def initialize(project:, qt_android: nil, qt_host: nil, android_sdk: nil, android_ndk: nil,
                     mruby_root: nil, mruby_json: nil, output: nil, device: nil,
                     device_kind: nil,
                     abi: DEFAULT_ABI, api: DEFAULT_API, target_api: DEFAULT_TARGET_API,
                     framework_root: FRAMEWORK_ROOT, environment: ENV,
                     host_platform: Platform.current, command: Command,
                     verify_reproducible: false, out: $stdout)
        @project = File.expand_path(project)
        @qt_android = expand_dependency(qt_android || environment["ZUI_QT_ANDROID"])
        @qt_host = expand_dependency(qt_host || environment["ZUI_QT_HOST"])
        @android_sdk = expand_dependency(
          android_sdk || environment["ANDROID_SDK_ROOT"] || environment["ANDROID_HOME"] || default_android_sdk
        )
        @android_ndk = expand_dependency(
          android_ndk || environment["ANDROID_NDK_ROOT"] || environment["ANDROID_NDK_HOME"] || default_android_ndk
        )
        @mruby_root = expand_dependency(mruby_root || environment["ZUI_MRUBY_ROOT"])
        @mruby_json = expand_dependency(mruby_json || environment["ZUI_MRUBY_JSON"])
        @abi = abi.to_s
        @api = Integer(api)
        @target_api = Integer(target_api)
        @home = File.expand_path(environment["HOME"] || Dir.home)
        @output = File.expand_path(output || File.join(@project, "dist", "android-#{@abi}"))
        @requested_device = device
        @device_kind = device_kind&.to_sym
        @framework_root = File.expand_path(framework_root)
        @source_date_epoch = ReproducibleBuild.epoch(environment["SOURCE_DATE_EPOCH"])
        @host_platform = host_platform
        @command = command
        @verify_reproducible = verify_reproducible == true
        @out = out
      end

      def build(install: true)
        validate!
        builds = @verify_reproducible ? [build_once, build_once] : [build_once]
        result = builds.last
        if builds.length == 2
          result.reproducibility = Reproducibility.verify!(builds.first.identity, result.identity)
          @out.puts("Verified two byte-identical Android APK builds: #{result.identity.artifact_sha256}")
        end
        if install
          device = select_device
          launched = install_and_launch(result.apk, result.bundle_id, device)
          launched.identity = result.identity
          launched.reproducibility = result.reproducibility
          result = launched
        end
        Reproducibility.write_metadata(result)
        result
      end

      private

      def build_once
        config = Dist.load(project: @project, platform: ANDROID_PLATFORM)
        bundle_id = android_identifier(config.identifier)
        stage = prepare_stage(config)
        build_name = "zui-android-#{@abi}-api#{@api}-bytecode"
        build_mruby(build_name)
        compile_application(stage)
        framework, framework_report, framework_manifest = prepare_framework
        finalize_stage(stage, config, bundle_id, framework_manifest:)
        @out.puts("Tree-shaken mobile Zui runtime: #{framework_report.components.size} components, " \
                  "#{(framework_report.saved_bytes / 1_000_000.0).round(1)} MB removed")
        build_directory = configure_native(config, bundle_id, stage, build_name, framework:)
        unsigned_apk = build_apk(build_directory)
        unsigned_sha256 = Digest::SHA256.file(unsigned_apk).hexdigest
        apk = sign_apk(unsigned_apk, config)
        identity = Reproducibility.android_identity(
          apk:, unsigned_sha256:, source_date_epoch: @source_date_epoch,
          toolchain: android_toolchain_identity(build_name)
        )
        Result.new(apk:, bundle_id:, identity:)
      end

      def expand_dependency(path)
        path && !path.empty? ? File.expand_path(path) : nil
      end

      def default_android_sdk
        path = File.join(Dir.home, "Library", "Android", "sdk")
        File.directory?(path) ? path : nil
      end

      def default_android_ndk
        return unless @android_sdk

        preferred = File.join(@android_sdk, "ndk", DEFAULT_NDK_VERSION)
        return preferred if File.directory?(preferred)
      end

      def validate!
        unless @host_platform.macos? || @host_platform.linux? || @host_platform.windows?
          raise ArgumentError, "Android applications must be built on macOS, Linux, or Windows"
        end
        raise ArgumentError, "mobile project directory not found: #{@project}" unless File.directory?(@project)
        raise ArgumentError, "mobile project is missing main.rb" unless File.file?(File.join(@project, "main.rb"))
        validate_directory!(@qt_android, "Qt Android SDK", "--qt-android or ZUI_QT_ANDROID")
        validate_directory!(@qt_host, "Qt host SDK", "--qt-host or ZUI_QT_HOST")
        validate_directory!(@android_sdk, "Android SDK", "--android-sdk or ANDROID_SDK_ROOT")
        validate_directory!(@android_ndk, "Android NDK", "--android-ndk or ANDROID_NDK_ROOT")
        validate_directory!(@mruby_root, "mruby source", "--mruby or ZUI_MRUBY_ROOT")
        validate_directory!(@mruby_json, "mruby-json source", "--mruby-json or ZUI_MRUBY_JSON")
        validate_file!(File.join(@qt_android, "bin", "qt-cmake"), "Qt Android qt-cmake")
        validate_file!(File.join(@qt_host, "bin", "androiddeployqt"), "Qt host androiddeployqt")
        validate_file!(File.join(@android_ndk, "build", "cmake", "android.toolchain.cmake"), "Android NDK toolchain")
        validate_file!(File.join(@android_sdk, "platform-tools", adb_name), "Android Debug Bridge")
        validate_file!(File.join(@mruby_root, "minirake"), "mruby minirake")
        validate_file!(File.join(@mruby_json, "mrbgem.rake"), "mruby-json gem")
        unless %w[arm64-v8a armeabi-v7a x86_64 x86].include?(@abi)
          raise ArgumentError, "Android ABI must be arm64-v8a, armeabi-v7a, x86_64, or x86"
        end
        unless [nil, :physical, :emulator].include?(@device_kind)
          raise ArgumentError, "Android device kind must be physical or emulator"
        end
        raise ArgumentError, "Android API must be at least 23" if @api < 23
        raise ArgumentError, "Android target API must be at least the minimum API" if @target_api < @api
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
        FileUtils.rm_rf(stage)
        FileUtils.mkdir_p(stage)
        File.binwrite(File.join(stage, "app.rb"), LiteSource.new(project: @project).call)
        copy_assets(stage, config)
        create_android_package(
          stage, config, config.icon_path(@project, ANDROID_PLATFORM),
          config.splash_path(@project, ANDROID_PLATFORM)
        )
        apply_android_overlay(stage)
        stage
      end

      def copy_assets(stage, config)
        Mobile.copy_project_assets(
          project: @project, stage:,
          excluding: Mobile.configured_release_assets(project: @project, config:)
        )
      end

      def create_android_package(stage, config, icon, splash)
        package = File.join(stage, "android")
        drawable = File.join(package, "res", "drawable")
        values = File.join(package, "res", "values")
        FileUtils.mkdir_p(drawable)
        FileUtils.mkdir_p(values)
        FileUtils.cp(icon, File.join(drawable, "zui_icon.png"))
        window_background = "#07110d"
        if splash
          FileUtils.cp(splash, File.join(drawable, "zui_splash.png"))
          File.write(File.join(drawable, "zui_launch_background.xml"), <<~XML)
            <?xml version="1.0" encoding="utf-8"?>
            <layer-list xmlns:android="http://schemas.android.com/apk/res/android">
                <item android:drawable="#07110d" />
                <item><bitmap android:src="@drawable/zui_splash" android:gravity="fill" /></item>
            </layer-list>
          XML
          window_background = "@drawable/zui_launch_background"
        end
        name = CGI.escapeHTML(config.name)
        version = CGI.escapeHTML(config.version)
        manifest = <<~XML
          <?xml version="1.0"?>
          <manifest xmlns:android="http://schemas.android.com/apk/res/android"
              android:installLocation="auto"
              android:versionCode="1"
              android:versionName="#{version}">
              <!-- %%INSERT_PERMISSIONS -->
              <!-- %%INSERT_FEATURES -->
              <supports-screens android:anyDensity="true" android:largeScreens="true"
                  android:normalScreens="true" android:smallScreens="true" />
              <application android:name="org.qtproject.qt.android.bindings.QtApplication"
                  android:allowBackup="true" android:fullBackupOnly="false"
                  android:hardwareAccelerated="true" android:icon="@drawable/zui_icon"
                  android:label="#{name}" android:theme="@style/ZuiTheme">
                  <activity android:name="org.qtproject.qt.android.bindings.QtActivity"
                      android:configChanges="orientation|uiMode|screenLayout|screenSize|smallestScreenSize|layoutDirection|locale|fontScale|keyboard|keyboardHidden|navigation|mcc|mnc|density"
                      android:exported="true" android:launchMode="singleTop"
                      android:screenOrientation="unspecified">
                      <intent-filter>
                          <action android:name="android.intent.action.MAIN" />
                          <category android:name="android.intent.category.LAUNCHER" />
                      </intent-filter>
                      <meta-data android:name="android.app.lib_name"
                          android:value="-- %%INSERT_APP_LIB_NAME%% --" />
                      <meta-data android:name="android.app.arguments"
                          android:value="-- %%INSERT_APP_ARGUMENTS%% --" />
                  </activity>
                  <provider android:name="androidx.core.content.FileProvider"
                      android:authorities="${applicationId}.qtprovider"
                      android:exported="false" android:grantUriPermissions="true">
                      <meta-data android:name="android.support.FILE_PROVIDER_PATHS"
                          android:resource="@xml/qtprovider_paths" />
                  </provider>
              </application>
          </manifest>
        XML
        File.write(File.join(package, "AndroidManifest.xml"), manifest)
        styles = <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <resources>
              <style name="ZuiTheme" parent="android:style/Theme.Material.Light.NoActionBar">
                  <item name="android:windowFullscreen">true</item>
                  <item name="android:windowNoTitle">true</item>
                  <item name="android:windowActionModeOverlay">true</item>
                  <item name="android:windowBackground">#{window_background}</item>
                  <item name="android:colorAccent">#66ffb2</item>
                  <item name="android:statusBarColor">#07110d</item>
                  <item name="android:navigationBarColor">#07110d</item>
                  <item name="android:enforceNavigationBarContrast">false</item>
                  <item name="android:windowLightStatusBar">false</item>
                  <item name="android:windowLightNavigationBar">false</item>
              </style>
          </resources>
        XML
        File.write(File.join(values, "styles.xml"), styles)
      end

      def apply_android_overlay(stage)
        source = File.join(@project, "android")
        return unless File.directory?(source)

        package = File.join(stage, "android")
        create_android_gradle_extension(package, source)
        entries = Dir.children(source).sort.reject { |entry| entry == ".DS_Store" }
        FileUtils.cp_r(entries.map { |entry| File.join(source, entry) }, package) unless entries.empty?
        validate_android_manifest!(File.join(package, "AndroidManifest.xml"))
      end

      def prepare_framework
        Mobile.prepare_framework(
          project: @project, output: @output, framework_root: @framework_root,
          platform: :android, runtime: :lite, source_date_epoch: @source_date_epoch
        )
      end

      def finalize_stage(stage, config, bundle_id, framework_manifest:)
        Mobile.finalize_payload(
          root: stage, platform: :android, runtime: :lite,
          source_date_epoch: @source_date_epoch,
          metadata: {
            "architecture" => @abi,
            "bundle_id" => bundle_id,
            "application_version" => config.version,
            "minimum_api" => @api,
            "target_api" => @target_api,
            "zui_payload_sha256" => framework_manifest.fetch("payload_sha256")
          }
        )
      end

      def create_android_gradle_extension(package, source)
        extension = File.join(source, "zui.gradle")
        return unless File.file?(extension)

        template = File.join(@qt_android, "src", "android", "templates", "build.gradle")
        validate_file!(template, "Qt Android Gradle template")
        contents = File.read(template).rstrip
        File.write(File.join(package, "build.gradle"), "#{contents}\n\napply from: 'zui.gradle'\n")
      end

      def validate_android_manifest!(manifest_path)
        raise ArgumentError, "android/AndroidManifest.xml is missing" unless File.file?(manifest_path)

        manifest = File.read(manifest_path)
        requirements = {
          "Qt activity" => "org.qtproject.qt.android.bindings.QtActivity",
          "application library marker" => "%%INSERT_APP_LIB_NAME%%",
          "permission marker" => "%%INSERT_PERMISSIONS",
          "feature marker" => "%%INSERT_FEATURES"
        }
        missing = requirements.reject { |_label, marker| manifest.include?(marker) }.keys
        return if missing.empty?

        raise ArgumentError,
              "android/AndroidManifest.xml must preserve Qt's #{missing.join(', ')}; " \
              "rerun `zui mobile --enable` after moving the custom manifest aside"
      end

      def android_identifier(identifier)
        identifier.to_s.split(".").map do |segment|
          normalized = segment.gsub(/[^A-Za-z0-9_]/, "_")
          normalized = "app_#{normalized}" unless normalized.match?(/\A[A-Za-z]/)
          normalized
        end.join(".")
      end

      def build_mruby(build_name)
        library = File.join(@mruby_root, "build", build_name, "lib", "libmruby.a")
        compiler = File.join(@mruby_root, "build", "host", "bin", "mrbc")
        if File.file?(library) && File.executable?(compiler)
          @out.puts("Mobile Ruby runtime: ready")
          return
        end

        @out.puts("Building the embedded Ruby runtime for Android #{@abi}...")
        configuration = File.join(@framework_root, "runtime", "mruby", "android_build_config.rb")
        validate_file!(configuration, "Zui Android mruby build configuration")
        run!([RbConfig.ruby, "minirake"], label: "building Android mruby", chdir: @mruby_root,
             env: {
               "SOURCE_DATE_EPOCH" => @source_date_epoch.to_s,
               "MRUBY_CONFIG" => configuration,
               "ZUI_ANDROID_NDK" => @android_ndk,
               "ZUI_ANDROID_ABI" => @abi,
               "ZUI_ANDROID_API" => @api.to_s,
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
        run!([compiler, "-o#{bytecode}", source], env: reproducible_environment,
             label: "precompiling the Ruby application", timeout: 120)
        raise ArgumentError, "mrbc did not produce #{bytecode}" unless File.file?(bytecode)
      end

      def configure_native(config, bundle_id, stage, build_name, framework: nil)
        build = File.join(@output, "build")
        FileUtils.rm_rf(build)
        FileUtils.mkdir_p(build)
        @out.puts("Generating the native Android application...")
        run!([
          File.join(@qt_android, "bin", "qt-cmake"), "-S", File.join(@framework_root, "native"),
          "-B", build, "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release",
          "-DCMAKE_MAKE_PROGRAM=#{ninja}", "-DQT_HOST_PATH=#{@qt_host}",
          "-DANDROID_SDK_ROOT=#{@android_sdk}", "-DANDROID_NDK_ROOT=#{@android_ndk}",
          "-DANDROID_ABI=#{@abi}", "-DANDROID_PLATFORM=android-#{@api}",
          "-DZUI_EMBEDDED_RUNTIME=ON", "-DZUI_MRUBY_ROOT=#{@mruby_root}",
          "-DZUI_FRAMEWORK_ROOT=#{framework || @framework_root}",
          "-DZUI_MRUBY_BUILD=#{build_name}", "-DZUI_MOBILE_APP_DIR=#{stage}",
          "-DZUI_MOBILE_APP_NAME=#{config.name}", "-DZUI_MOBILE_BUNDLE_ID=#{bundle_id}",
          "-DZUI_MOBILE_APP_VERSION=#{config.version}", "-DZUI_MOBILE_BUILD_VERSION=1",
          "-DZUI_ANDROID_PACKAGE_SOURCE_DIR=#{File.join(stage, 'android')}",
          "-DZUI_ANDROID_PROJECT_DIR=#{File.join(@project, 'android')}",
          "-DZUI_ANDROID_MIN_SDK=#{@api}", "-DZUI_ANDROID_TARGET_SDK=#{@target_api}"
        ], label: "generating the Android build", env: reproducible_environment, timeout: 300)
        build
      end

      def build_apk(build)
        @out.puts("Building the Android APK...")
        run!([cmake, "--build", build, "--target", "apk", "--parallel"], env: reproducible_environment,
             label: "building the Android APK", timeout: 1_800, max_output_bytes: 64_000_000)
        apk = File.join(build, "android-build", "zui-host.apk")
        raise ArgumentError, "Android build did not produce #{apk}" unless File.file?(apk)

        ReproducibleBuild.normalize_zip(apk, epoch: @source_date_epoch)
        apk
      end

      def sign_apk(unsigned_apk, config)
        tools = android_build_tools
        keystore = File.join(@home, ".android", "debug.keystore")
        validate_file!(keystore, "Android debug keystore")
        name = config.name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|\z/, "")
        aligned = File.join(@output, "#{name}-aligned.apk")
        signed = File.join(@output, "#{name}-#{@abi}.apk")
        FileUtils.rm_f([aligned, signed, "#{signed}.idsig"])
        run!([File.join(tools, "zipalign"), "-f", "4", unsigned_apk, aligned],
             label: "aligning the Android APK", timeout: 120)
        run!([
          File.join(tools, "apksigner"), "sign", "--ks", keystore,
          "--ks-key-alias", "androiddebugkey", "--ks-pass", "pass:android",
          "--key-pass", "pass:android", "--v4-signing-enabled", "false", "--out", signed, aligned
        ], label: "signing the Android APK", timeout: 120)
        FileUtils.rm_f(aligned)
        run!([File.join(tools, "apksigner"), "verify", "--verbose", signed],
             label: "verifying the Android APK", timeout: 120)
        signed
      end

      def android_build_tools
        path = File.join(@android_sdk, "build-tools", DEFAULT_BUILD_TOOLS_VERSION)
        tools = %w[apksigner zipalign].map { |name| File.join(path, executable_name(name)) }
        unless tools.all? { |tool| File.executable?(tool) }
          raise ArgumentError,
                "Android SDK build tools #{DEFAULT_BUILD_TOOLS_VERSION} were not found; " \
                "run `zui mobile --fix`"
        end

        path
      end

      def ninja
        pinned_cmake_tool("ninja")
      end

      def cmake
        pinned_cmake_tool("cmake")
      end

      def pinned_cmake_tool(name)
        path = File.join(@android_sdk, "cmake", DEFAULT_CMAKE_VERSION, "bin", executable_name(name))
        return path if File.executable?(path)

        raise ArgumentError, "Android SDK CMake #{DEFAULT_CMAKE_VERSION} is missing #{name}; run `zui mobile --fix`"
      end

      def reproducible_environment
        { "SOURCE_DATE_EPOCH" => @source_date_epoch.to_s, "ZERO_AR_DATE" => "1" }
      end

      def android_toolchain_identity(build_name)
        library = File.join(@mruby_root, "build", build_name, "lib", "libmruby.a")
        {
          "qt" => Setup::QT_VERSION,
          "android_ndk" => DEFAULT_NDK_VERSION,
          "android_build_tools" => DEFAULT_BUILD_TOOLS_VERSION,
          "cmake" => DEFAULT_CMAKE_VERSION,
          "abi" => @abi,
          "minimum_api" => @api,
          "target_api" => @target_api,
          "ruby_runtime" => "mruby",
          "ruby_runtime_sha256" => Digest::SHA256.file(library).hexdigest
        }
      end

      def adb
        File.join(@android_sdk, "platform-tools", adb_name)
      end

      def adb_name
        executable_name("adb")
      end

      def executable_name(name)
        @host_platform.windows? ? "#{name}.exe" : name
      end

      def select_device
        devices = connected_devices
        if @requested_device
          match = devices.find { |serial, _state| serial == @requested_device }
          raise ArgumentError, "requested Android device is not connected: #{@requested_device}" unless match
          raise ArgumentError, "Android device #{@requested_device} is #{match.last}; authorize USB debugging" unless match.last == "device"
          validate_device_kind!(@requested_device)
          verify_device_abi(@requested_device)
          return @requested_device
        end

        available = devices.select { |_serial, state| state == "device" }
        available.select! { |serial, _state| device_matches_kind?(serial) } if @device_kind
        if available.empty? && @device_kind == :emulator
          start_emulator
          devices = connected_devices
          available = devices.select do |serial, state|
            state == "device" && device_matches_kind?(serial)
          end
        end
        if available.empty?
          blocked = devices.map { |serial, state| "#{serial} (#{state})" }.join(", ")
          message = if @device_kind == :physical
                      "no authorized physical Android device is connected"
                    elsif @device_kind == :emulator
                      "no compatible Android emulator is running"
                    else
                      "no authorized Android device is connected"
                    end
          message += ": #{blocked}" unless blocked.empty?
          hint = @device_kind == :emulator ? "create an Android virtual device and rerun the command" : "connect a phone with USB debugging enabled"
          raise ArgumentError, "#{message}; #{hint}"
        end
        device = available.first.first
        verify_device_abi(device)
        device
      end

      def connected_devices
        output = command_output([adb, "devices"], label: "listing Android devices")
        output.lines.filter_map do |line|
          serial, state = line.split
          [serial, state] if serial && state && serial != "List"
        end
      end

      def validate_device_kind!(device)
        return if !@device_kind || device_matches_kind?(device)

        actual = emulator_device?(device) ? "an emulator" : "a physical device"
        raise ArgumentError, "Android device #{device} is #{actual}, not the requested #{@device_kind} target"
      end

      def device_matches_kind?(device)
        emulator = emulator_device?(device)
        @device_kind == :emulator ? emulator : !emulator
      end

      def emulator_device?(device)
        return true if device.start_with?("emulator-")

        result = @command.run([adb, "-s", device, "shell", "getprop", "ro.kernel.qemu"],
                              timeout: 15, max_output_bytes: 1_000_000)
        result.success? && result.stdout.strip == "1"
      end

      def start_emulator
        executable = File.join(@android_sdk, "emulator", executable_name("emulator"))
        validate_file!(executable, "Android emulator")
        avds = command_output([executable, "-list-avds"], label: "listing Android virtual devices").lines.map(&:strip).reject(&:empty?)
        raise ArgumentError, "no Android virtual device is configured; create one in Android Studio" if avds.empty?

        FileUtils.mkdir_p(@output)
        log = File.open(File.join(@output, "emulator.log"), "ab")
        @out.puts("Starting Android emulator #{avds.first}...")
        pid = Process.spawn(executable, "-avd", avds.first, "-no-snapshot-save", out: log, err: log)
        Process.detach(pid)
        log.close

        60.times do
          sleep(1)
          candidate = connected_devices.find do |serial, state|
            state == "device" && device_matches_kind?(serial) && emulator_booted?(serial)
          end
          return candidate.first if candidate
        end
        raise ArgumentError, "Android emulator did not finish booting; see #{File.join(@output, 'emulator.log')}"
      ensure
        log&.close unless log&.closed?
      end

      def emulator_booted?(device)
        result = @command.run([adb, "-s", device, "shell", "getprop", "sys.boot_completed"],
                              timeout: 15, max_output_bytes: 1_000_000)
        result.success? && result.stdout.strip == "1"
      end

      def verify_device_abi(device)
        abis = command_output([adb, "-s", device, "shell", "getprop", "ro.product.cpu.abilist"],
                              label: "checking Android device architecture")
        return if abis.split(",").include?(@abi)

        raise ArgumentError, "Android device #{device} does not support #{@abi}; reported #{abis}"
      end

      def install_and_launch(apk, bundle_id, device)
        @out.puts("Installing and launching on Android device #{device}...")
        run!([adb, "-s", device, "install", "-r", apk],
             label: "installing the Android application", timeout: 300)
        run!([adb, "-s", device, "shell", "am", "force-stop", bundle_id],
             label: "stopping the previous Android application", timeout: 60)
        run!([
          adb, "-s", device, "shell", "am", "start", "-W", "-n",
          "#{bundle_id}/org.qtproject.qt.android.bindings.QtActivity"
        ], label: "launching the Android application", timeout: 120)
        pid = wait_for_pid(device, bundle_id)
        unless pid
          logs = command_output([adb, "-s", device, "logcat", "-d", "-t", "200"],
                                label: "reading Android launch logs", timeout: 60)
          raise ArgumentError, "Android application exited during launch:\n#{logs.byteslice(-8_000, 8_000)}"
        end
        Result.new(apk:, bundle_id:, device:, pid:)
      end

      def wait_for_pid(device, bundle_id)
        20.times do
          result = @command.run([adb, "-s", device, "shell", "pidof", bundle_id],
                                timeout: 15, max_output_bytes: 1_000_000)
          pid = result.stdout.strip.split.first
          return pid.to_i if result.success? && pid && !pid.empty?

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
