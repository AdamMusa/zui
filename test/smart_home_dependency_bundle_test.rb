# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class SmartHomeDependencyBundleTest < Minitest::Test
  PROJECT = File.expand_path("../examples/smart_home_energy", __dir__)

  def test_application_locks_zui_without_becoming_a_gem
    specs = Zui::LockedGems.new.specs(PROJECT).reject(&:default_gem?)

    assert_equal ["zui"], specs.map(&:name)
    zui = specs.first
    assert_equal "zui-#{Zui::VERSION}", zui.full_name
    assert_includes zui.files, "lib/zui.rb"
    refute File.exist?(File.join(PROJECT, "smart_home_energy.gemspec"))
  end
end
