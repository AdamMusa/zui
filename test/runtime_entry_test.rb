# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"

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
end
