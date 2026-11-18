# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "zui"

class RuntimeEntryTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_runtime_entry_loads_only_the_application_api
    script = <<~RUBY
      require "zui/runtime_entry"
      abort "missing application API" unless Zui.respond_to?(:app) && defined?(Zui::Application)
      abort "loaded distribution tooling" if defined?(Zui::Distribution) || defined?(Zui::Mobile)
      puts Zui::VERSION
    RUBY

    output, error, status = Open3.capture3(RbConfig.ruby, "-I#{File.join(ROOT, 'lib')}", "-e", script)

    assert status.success?, error
    assert_equal "0.0.10\n", output
  end

  # An application says `require "zui"`, not `require "zui/runtime_entry"`, and
  # that used to drag in the whole build and distribution half of the framework
  # — gem packaging, tree shaking, client downloads, mobile projects, Bundler —
  # before the application had built a single node. It was paid twice on every
  # `zui run`: by the command, and again by the process it spawns.
  BUILD_ONLY_SOURCES = %w[
    zui/client.rb zui/distribution.rb zui/dist_packager.rb zui/full_runtime.rb
    zui/generator.rb zui/locked_gems.rb zui/mobile.rb zui/ruby_runtime_shaker.rb
    zui/tree_shaker.rb
  ].freeze

  def test_requiring_zui_does_not_load_the_build_and_distribution_tooling
    script = <<~RUBY
      require "zui"
      loaded = $LOADED_FEATURES.select { |path| #{BUILD_ONLY_SOURCES.inspect}.any? { |tail| path.end_with?(tail) } }
      abort "eagerly loaded: \#{loaded.join(', ')}" unless loaded.empty?
      abort "missing application API" unless Zui.respond_to?(:app) && defined?(Zui::Application)
      puts "lean"
    RUBY

    output, error, status = Open3.capture3(RbConfig.ruby, "-I#{File.join(ROOT, 'lib')}", "-e", script)

    assert status.success?, error
    assert_equal "lean\n", output
  end

  # Deferring those files is only safe while every constant they used to define
  # still answers to its name, so the command keeps working unchanged.
  DEFERRED_CONSTANTS = %i[
    ApplicationRuntime Client Command CommandOutputLimit CommandTimeout Dist
    DistPackager Distribution FullRuntime Generator Host LiteRuntime LiteSource
    LockedGems MacOSArchitecture MacOSBundleSeal MacOSQmlPayload Mobile
    PEDependencies Platform QtBundleConfiguration ReproducibleBuild
    RubyRuntimeShaker Runner Runtime SourceBundle TreeShaker
  ].freeze

  def test_every_deferred_constant_still_resolves_through_require_zui
    script = <<~RUBY
      require "zui"
      missing = #{DEFERRED_CONSTANTS.inspect}.reject do |name|
        begin
          Zui.const_get(name)
          true
        rescue StandardError, LoadError
          false
        end
      end
      abort "unresolvable: \#{missing.join(', ')}" unless missing.empty?
      puts #{DEFERRED_CONSTANTS.size}
    RUBY

    output, error, status = Open3.capture3(RbConfig.ruby, "-I#{File.join(ROOT, 'lib')}", "-e", script)

    assert status.success?, error
    assert_equal "#{DEFERRED_CONSTANTS.size}\n", output
  end

  # The packaged runtime replaces lib/zui.rb with a require of the runtime
  # entrypoint, so anything the entrypoint now pulls in has to be on the list
  # of files that ship with it.
  def test_the_packaged_runtime_ships_every_file_the_entrypoint_requires
    required = File.read(File.join(ROOT, "lib", "zui", "runtime_entry.rb"))
                   .scan(/require_relative "([a-z_]+)"/).flatten

    refute_empty required

    required.each do |name|
      assert_includes Zui::FullRuntime::ZUI_RUNTIME_FILES, "lib/zui/#{name}.rb",
                      "the packaged runtime would be missing lib/zui/#{name}.rb"
    end
  end
end
