# frozen_string_literal: true

require_relative "lib/zui"

Gem::Specification.new do |spec|
  spec.name = "zui"
  spec.version = Zui::VERSION
  spec.summary = "Build beautiful native desktop applications in pure Ruby"
  spec.description = "First-class UI, state, events, animation, media, GPU effects, and 3D for Ruby desktop applications."
  spec.authors = ["Adam Moussa Ali"]
  spec.license = "MIT"
  spec.homepage = "https://github.com/AdamMusa/zui"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "#{spec.homepage}#readme"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.1"
  spec.files = Dir[
    "bin/*", "lib/**/*.rb", "*.qml", "Components/**/*", "Controls/**/*", "Theme/**/*", "Fonts/**/*",
    "README.md", "LICENSE", "THIRD_PARTY_NOTICES.md"
  ].reject do |path|
    path.match?(%r{\Alib/zui/(?:client_(?:builder|packager)|lite_runtime_packager)\.rb\z})
  end
  spec.require_paths = ["lib"]
  spec.bindir = "bin"
  spec.executables = ["zui"]
end
