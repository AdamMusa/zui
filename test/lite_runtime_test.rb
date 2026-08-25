# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class LiteRuntimeTest < Minitest::Test
  def test_verified_archive_configures_and_installs_a_standalone_lite_program
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.current.assert_supported!
      executable = File.join(directory, platform.windows? ? "mruby.exe" : "mruby")
      File.binwrite(executable, "mruby-fixture")
      FileUtils.chmod(0o755, executable) unless platform.windows?
      archive = Zui::LiteRuntimePackager.new(platform:).package(
        executable:, output: File.join(directory, "release")
      )
      runtime = Zui::LiteRuntime.new(
        platform:, cache_root: File.join(directory, "cache"),
        environment: {
          "ZUI_LITE_RUNTIME_ARCHIVE" => archive,
          "ZUI_LITE_RUNTIME_CHECKSUM" => "#{archive}.sha256"
        }
      )

      refute runtime.configured?
      runtime.configure!
      assert runtime.configured?
      assert_equal "mruby", runtime.manifest.fetch("engine")

      project = File.join(directory, "project")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "main.rb"), <<~RUBY)
        require "zui"
        Zui.app { app(title: "Lite") { text "ready" } }
      RUBY
      destination = File.join(directory, "bundle-runtime")
      descriptor = runtime.install(project:, destination:)

      assert_equal "mruby", descriptor.engine
      assert_equal "app.rb", descriptor.program
      assert_equal "", descriptor.load_path
      assert File.file?(File.join(destination, "bin", platform.windows? ? "mruby.exe" : "mruby"))
      source = File.read(File.join(destination, "app.rb"))
      assert_includes source, 'title: "Lite"'
      refute_match(/^\s*require\b/, source)
      manifest = JSON.parse(File.read(File.join(destination, "runtime.json")))
      assert_equal "app.rb", manifest.fetch("program")
      assert_equal "", manifest.fetch("load_path")
    end
  end

  def test_archive_checksum_is_mandatory
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.current.assert_supported!
      executable = File.join(directory, platform.windows? ? "mruby.exe" : "mruby")
      File.binwrite(executable, "mruby-fixture")
      FileUtils.chmod(0o755, executable) unless platform.windows?
      archive = Zui::LiteRuntimePackager.new(platform:).package(
        executable:, output: File.join(directory, "release")
      )
      File.write("#{archive}.sha256", "#{'0' * 64}  #{File.basename(archive)}\n")
      runtime = Zui::LiteRuntime.new(
        platform:, cache_root: File.join(directory, "cache"),
        environment: {
          "ZUI_LITE_RUNTIME_ARCHIVE" => archive,
          "ZUI_LITE_RUNTIME_CHECKSUM" => "#{archive}.sha256"
        }
      )

      error = assert_raises(ArgumentError) { runtime.configure! }
      assert_includes error.message, "checksum mismatch"
      refute runtime.configured?
    end
  end
end
