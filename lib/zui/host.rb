# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Zui
  class Host
    attr_reader :platform

    def initialize(platform: Platform.current, framework_root: FRAMEWORK_ROOT, environment: ENV)
      @platform = platform.assert_supported!
      @framework_root = framework_root
      @environment = environment
    end

    def executable(build: true)
      override = @environment["ZUI_HOST"]
      return checked_executable(override) if override && !override.empty?
      return bundled if File.executable?(bundled)
      return cached if File.executable?(cached)
      return nil unless build

      build!(cached)
    end

    def available? = !executable(build: false).nil?

    def build!(destination = cached)
      cmake = find_command("cmake")
      raise ArgumentError, platform_help unless cmake

      FileUtils.mkdir_p(File.dirname(destination))
      Dir.mktmpdir("zui-host-build-") do |build_dir|
        configure = Command.run([
          cmake, "-S", File.join(@framework_root, "native"), "-B", build_dir,
          "-DCMAKE_BUILD_TYPE=Release"
        ], timeout: 180, max_output_bytes: 4_194_304)
        raise ArgumentError, "Zui host configuration failed:\n#{configure.stderr}" unless configure.success?

        compile = Command.run([cmake, "--build", build_dir, "--config", "Release", "--parallel"],
                              timeout: 600, max_output_bytes: 8_388_608)
        raise ArgumentError, "Zui host build failed:\n#{compile.stderr}" unless compile.success?

        built = locate_build(build_dir)
        raise ArgumentError, "Zui host build produced no executable" unless built
        temporary = "#{destination}.install-#{Process.pid}"
        FileUtils.cp(built, temporary)
        FileUtils.chmod(0o755, temporary)
        File.rename(temporary, destination)
      ensure
        FileUtils.rm_f(temporary) if temporary && File.exist?(temporary)
      end
      destination
    end

    def platform_help
      if platform.macos?
        "building Zui on macOS requires CMake and Qt 6 (for example: brew install cmake qt)"
      else
        "building Zui on Linux requires CMake, a C++17 compiler, and Qt 6 Core/Gui/Qml/Quick development packages"
      end
    end

    private

    def bundled
      File.join(@framework_root, "vendor", "host", platform.id, executable_name)
    end

    def cached
      cache_root = @environment["XDG_CACHE_HOME"]
      cache_root = File.expand_path("~/.cache") if cache_root.nil? || cache_root.empty?
      File.join(cache_root, "zui", "host", VERSION, platform.id, executable_name)
    end

    def executable_name = platform.os == :windows ? "zui-host.exe" : "zui-host"

    def checked_executable(path)
      expanded = File.expand_path(path)
      raise ArgumentError, "ZUI_HOST is not executable: #{expanded}" unless File.executable?(expanded)
      expanded
    end

    def find_command(name)
      @environment.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
        path = File.join(directory, name)
        return path if File.executable?(path) && !File.directory?(path)
      end
      nil
    end

    def locate_build(build_dir)
      candidates = [
        File.join(build_dir, executable_name),
        File.join(build_dir, "Release", executable_name),
        File.join(build_dir, "zui-host.app", "Contents", "MacOS", "zui-host")
      ]
      candidates.find { |path| File.executable?(path) }
    end
  end
end
