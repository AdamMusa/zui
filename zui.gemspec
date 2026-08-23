# frozen_string_literal: true

require_relative "lib/zui"

Gem::Specification.new do |spec|
  spec.name = "zui"
  spec.version = Zui::VERSION
  spec.summary = "Build cross-platform native desktop applications in Ruby"
  spec.description = "A platform-neutral Ruby UI framework powered by Qt and QML."
  spec.authors = ["Adam Moussa Ali"]
  spec.license = "MIT"
  spec.homepage = "https://github.com/AdamMusa/zui"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "#{spec.homepage}#readme"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.1"
  spec.files = Dir[
    "bin/*", "lib/**/*.rb", "*.qml", "Components/**/*", "Controls/**/*", "Theme/**/*",
    "native/**/*", "README.md", "LICENSE"
  ]
  spec.require_paths = ["lib"]
end
