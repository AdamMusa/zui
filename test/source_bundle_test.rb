# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class SourceBundleTest < Minitest::Test
  def test_strips_zui_from_an_embedded_runtime_bundle
    Dir.mktmpdir do |directory|
      entrypoint = File.join(directory, "main.rb")
      File.write(entrypoint, "require \"zui\"\nputs \"app\"\n")

      bundled = Zui::SourceBundle.new(entrypoint).call

      refute_includes bundled, 'require "zui"'
      assert_includes bundled, 'puts "app"'
    end
  end

  def test_adapter_can_declare_an_additional_embedded_framework
    Dir.mktmpdir do |directory|
      entrypoint = File.join(directory, "main.rb")
      File.write(entrypoint, "require \"omarchy_ui\"\nputs \"plugin\"\n")

      bundled = Zui::SourceBundle.new(
        entrypoint,
        embedded_frameworks: %w[zui omarchy_ui]
      ).call

      refute_includes bundled, 'require "omarchy_ui"'
      assert_includes bundled, 'puts "plugin"'
    end
  end
end
