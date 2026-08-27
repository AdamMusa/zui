# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class SmartHomeProjectGemTest < Minitest::Test
  PROJECT = File.expand_path("../examples/smart_home_energy", __dir__)

  def test_resolves_the_application_and_framework_as_locked_path_gems
    specs = Zui::LockedGems.new.specs(PROJECT).reject(&:default_gem?)

    assert_equal %w[smart-home-energy zui], specs.map(&:name).sort
    application = specs.find { |spec| spec.name == "smart-home-energy" }
    assert_equal "smart-home-energy-0.1.0", application.full_name
    assert_equal PROJECT, application.full_gem_path
    assert_equal ["lib"], application.require_paths
    assert_equal ["README.md", "lib/smart_home_energy.rb", "lib/smart_home_energy/version.rb"],
                 application.files.sort
  end

  def test_application_gemspec_contains_only_its_project_library
    specification = Gem::Specification.load(File.join(PROJECT, "smart_home_energy.gemspec"))

    assert_equal ["README.md", "lib/smart_home_energy.rb", "lib/smart_home_energy/version.rb"],
                 specification.files.sort
    assert_equal ["zui (~> 0.0.10)"], specification.runtime_dependencies.map(&:to_s)
  end
end
