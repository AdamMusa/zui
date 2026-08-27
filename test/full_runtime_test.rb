# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class FullRuntimeTest < Minitest::Test
  FakeSpec = Struct.new(:name, :version, :full_gem_path, :extension_dir, :files, :default, keyword_init: true) do
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
      FileUtils.mkdir_p(File.join(app_spec.full_gem_path, "dist"))
      File.binwrite(File.join(app_spec.full_gem_path, "dist", "development-build.bin"), "must not ship")
      native_extension = File.join(
        directory, "installed-gems", "extensions", "x86_64-linux", "3.3.0", app_spec.full_name
      )
      native_dependency = File.join(prefix, "lib", "libpaint.so")
      FileUtils.mkdir_p(native_extension)
      File.binwrite(File.join(native_extension, "paint.bundle"), "native-gem-fixture")
      File.binwrite(native_dependency, "native-dependency-fixture")
      app_spec.extension_dir = native_extension
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
      runtime.define_singleton_method(:dependencies) do |binary|
        File.basename(binary) == "paint.bundle" ? [native_dependency] : []
      end

      descriptor = runtime.install(project:, destination:)

      assert_equal "cruby", descriptor.engine
      assert_equal ["paint-1.2.3"], descriptor.gems
      assert_equal "bin/ruby", descriptor.executable
      assert File.file?(File.join(destination, "bin", "ruby"))
      assert File.file?(File.join(destination, "lib", "ruby", "3.3.0", "json.rb"))
      assert File.file?(File.join(destination, "lib", "ruby", "3.3.0", "x86_64-linux", "json.so"))
      assert File.file?(File.join(destination, "lib", "libruby.so"))
      assert File.file?(File.join(destination, "gems", "gems", "paint-1.2.3", "lib", "paint.rb"))
      refute File.exist?(File.join(destination, "gems", "gems", "paint-1.2.3", "dist"))
      assert File.file?(File.join(destination, "gems", "specifications", "paint-1.2.3.gemspec"))
      assert File.file?(File.join(destination, "lib", "libpaint.so"))
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
      locked_gems = Zui::LockedGems.new

      error = assert_raises(ArgumentError) { locked_gems.specs(project) }

      assert_includes error.message, "Gemfile.lock"
      assert_includes error.message, "bundle install"
    end
  end

  def test_locked_gems_snapshot_local_path_specs_before_bundler_resets
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      gem_root = File.join(project, "vendor", "paint")
      FileUtils.mkdir_p(File.join(gem_root, "lib"))
      File.write(File.join(gem_root, "paint.gemspec"), <<~RUBY)
        Gem::Specification.new do |spec|
          spec.name = "paint"
          spec.version = "1.2.3"
          spec.summary = "Paint fixture"
          spec.authors = ["Zui"]
          spec.files = ["lib/paint.rb"]
        end
      RUBY
      File.write(File.join(gem_root, "lib", "paint.rb"), "module Paint; end\n")
      File.write(File.join(project, "Gemfile"), <<~RUBY)
        source "https://rubygems.org"
        gem "paint", path: "vendor/paint"
      RUBY
      File.write(File.join(project, "Gemfile.lock"), <<~LOCK)
        PATH
          remote: vendor/paint
          specs:
            paint (1.2.3)

        GEM
          remote: https://rubygems.org/
          specs:

        PLATFORMS
          ruby

        DEPENDENCIES
          paint!
      LOCK

      specs = nil
      capture_io { specs = Zui::LockedGems.new.specs(project) }
      spec = specs.find { |candidate| candidate.name == "paint" }

      assert_equal "paint-1.2.3", spec.full_name
      assert_equal gem_root, spec.full_gem_path
      assert_equal ["lib"], spec.require_paths
      assert_equal ["lib/paint.rb"], spec.files
      assert_includes spec.to_ruby, 'name = "paint"'
    end
  end

  def test_resigns_a_stripped_macos_ruby_executable
    Dir.mktmpdir do |directory|
      ruby = File.join(directory, "source", "bin", "ruby")
      destination = File.join(directory, "runtime")
      FileUtils.mkdir_p(File.dirname(ruby))
      File.binwrite(ruby, "\xCF\xFA\xED\xFE".b + "ruby-fixture")
      FileUtils.chmod(0o755, ruby)
      runtime = Zui::FullRuntime.new(
        platform: Zui::Platform.new(os: :macos, arch: :arm64), ruby:, environment: { "PATH" => "" }
      )
      commands = []
      runtime.define_singleton_method(:find_command) { |names| File.join("/usr/bin", names.first) }
      runtime.define_singleton_method(:system) do |*arguments, **options|
        commands << [arguments, options]
        true
      end

      executable = runtime.send(:install_executable, destination)

      assert_equal "bin/ruby", executable
      assert_equal ["/usr/bin/strip", "-x", File.join(destination, "bin", "ruby")], commands[0][0]
      assert_equal [
        "/usr/bin/codesign", "--force", "--sign", "-", "--timestamp=none",
        File.join(destination, "bin", "ruby")
      ], commands[1][0]
    end
  end

  def test_preserves_runtime_library_symlinks_without_duplicate_payloads
    Dir.mktmpdir do |directory|
      source = File.join(directory, "source")
      library = File.join(source, "lib", "libruby.so.3.3")
      alias_path = File.join(source, "lib", "libruby.so")
      destination = File.join(directory, "runtime")
      FileUtils.mkdir_p(File.dirname(library))
      File.binwrite(library, "ruby-library")
      File.symlink(File.basename(library), alias_path)
      runtime = Zui::FullRuntime.new(
        platform: Zui::Platform.new(os: :linux, arch: :x86_64),
        rbconfig: { "libdir" => File.dirname(library) }
      )

      runtime.send(:install_runtime_libraries, destination)

      installed_library = File.join(destination, "lib", File.basename(library))
      installed_alias = File.join(destination, "lib", File.basename(alias_path))
      assert_equal "ruby-library", File.binread(installed_library)
      assert File.symlink?(installed_alias)
      assert_equal File.basename(library), File.readlink(installed_alias)
    end
  end

  private

  def fake_spec(root, name, version, default: false)
    path = File.join(root, "installed-gems", "#{name}-#{version}")
    FileUtils.mkdir_p(File.join(path, "lib"))
    File.write(File.join(path, "lib", "#{name.tr('-', '_')}.rb"), "# fixture\n")
    FakeSpec.new(
      name:, version:, full_gem_path: path, extension_dir: nil,
      files: ["lib/#{name.tr('-', '_')}.rb"], default:
    )
  end
end
