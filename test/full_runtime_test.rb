# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class FullRuntimeTest < Minitest::Test
  FakeSpec = Struct.new(:name, :version, :full_gem_path, :extension_dir, :default, keyword_init: true) do
    def full_name = "#{name}-#{version}"
    def default_gem? = default == true
    def to_ruby = "Gem::Specification.new { |spec| spec.name = #{name.dump}; spec.version = #{version.dump} }\n"
  end

  def test_installs_private_cruby_standard_library_and_only_project_gems
    Dir.mktmpdir do |directory|
      prefix = File.join(directory, "ruby-source")
      ruby = File.join(prefix, "bin", "ruby")
      standard_library = File.join(prefix, "lib", "ruby", "3.3.0")
      architecture_library = File.join(standard_library, "x86_64-linux")
      FileUtils.mkdir_p([File.dirname(ruby), architecture_library, File.join(prefix, "lib")])
      File.binwrite(ruby, "ruby-fixture")
      FileUtils.chmod(0o755, ruby)
      File.write(File.join(standard_library, "json.rb"), "module JSON; end\n")
      File.binwrite(File.join(architecture_library, "json.so"), "native-fixture")
      File.binwrite(File.join(prefix, "lib", "libruby.so"), "library-fixture")

      project = File.join(directory, "project")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "Gemfile"), "source 'https://rubygems.org'\n")
      File.write(File.join(project, "Gemfile.lock"), "GEM\n  specs:\n")
      app_spec = fake_spec(directory, "paint", "1.2.3")
      zui_spec = fake_spec(directory, "zui", Zui::VERSION)
      default_spec = fake_spec(directory, "json", "2.0.0", default: true)
      destination = File.join(directory, "runtime")
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      runtime = Zui::FullRuntime.new(
        platform:, ruby:, environment: { "PATH" => "" },
        rbconfig: {
          "prefix" => prefix,
          "bindir" => File.join(prefix, "bin"),
          "libdir" => File.join(prefix, "lib"),
          "rubylibdir" => standard_library,
          "archdir" => architecture_library,
          "ruby_version" => "3.3.0"
        },
        spec_loader: ->(_project) { [app_spec, zui_spec, default_spec] }
      )

      descriptor = runtime.install(project:, destination:)

      assert_equal "cruby", descriptor.engine
      assert_equal ["paint-1.2.3"], descriptor.gems
      assert_equal "bin/ruby", descriptor.executable
      assert File.file?(File.join(destination, "bin", "ruby"))
      assert File.file?(File.join(destination, "lib", "ruby", "3.3.0", "json.rb"))
      assert File.file?(File.join(destination, "lib", "ruby", "3.3.0", "x86_64-linux", "json.so"))
      assert File.file?(File.join(destination, "lib", "libruby.so"))
      assert File.file?(File.join(destination, "gems", "gems", "paint-1.2.3", "lib", "paint.rb"))
      assert File.file?(File.join(destination, "gems", "specifications", "paint-1.2.3.gemspec"))
      refute File.exist?(File.join(destination, "gems", "gems", "zui-#{Zui::VERSION}"))
      refute File.exist?(File.join(destination, "gems", "gems", "json-2.0.0"))
      manifest = JSON.parse(File.read(File.join(destination, "runtime.json")))
      assert_equal "cruby", manifest.fetch("engine")
      assert_equal ["gems"], manifest.fetch("environment").fetch("GEM_HOME")
    end
  end

  def test_requires_a_locked_gemfile_for_full_bundles
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      FileUtils.mkdir_p(project)
      File.write(File.join(project, "Gemfile"), "source 'https://rubygems.org'\n")
      runtime = Zui::FullRuntime.new

      error = assert_raises(ArgumentError) { runtime.send(:project_specs, project) }

      assert_includes error.message, "Gemfile.lock"
      assert_includes error.message, "bundle install"
    end
  end

  private

  def fake_spec(root, name, version, default: false)
    path = File.join(root, "installed-gems", "#{name}-#{version}")
    FileUtils.mkdir_p(File.join(path, "lib"))
    File.write(File.join(path, "lib", "#{name.tr('-', '_')}.rb"), "# fixture\n")
    FakeSpec.new(name:, version:, full_gem_path: path, extension_dir: nil, default:)
  end
end
