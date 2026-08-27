# frozen_string_literal: true

require_relative "lib/smart_home_energy/version"

Gem::Specification.new do |spec|
  spec.name = "smart-home-energy"
  spec.version = SmartHomeEnergy::VERSION
  spec.summary = "Habitat One smart-home energy dashboard"
  spec.description = "A responsive native smart-home energy dashboard built with Zui."
  spec.authors = ["Zui Project"]
  spec.license = "MIT"
  spec.homepage = "https://github.com/AdamMusa/zui"
  spec.required_ruby_version = ">= 3.1"
  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*.rb"] + ["README.md"] }
  spec.require_paths = ["lib"]
  spec.add_dependency "zui", "~> 0.0.10"
end
