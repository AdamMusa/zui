# frozen_string_literal: true

# An application needs the control-tree runtime and nothing else. The other
# half of the framework — client downloads, gem packaging, tree shaking, mobile
# projects, distribution — is reached only through the `zui` command, and
# loading it eagerly cost every single application a quarter of a second before
# its first node existed. Worse, that cost was paid twice on every `zui run`:
# once by the command and again by the application process it spawns.
#
# A packaged application never paid it, because FullRuntime rewrites this file
# as `require_relative "zui/runtime_entry"` when it installs the runtime. The
# autoloads below give development the same startup as production while leaving
# `require "zui"` able to reach every constant it always could.
require_relative "zui/runtime_entry"

Zui::Trace.mark("framework-load-end")

module Zui
  lazy = ->(file) { File.expand_path("zui/#{file}.rb", __dir__) }

  autoload :ApplicationRuntime, lazy["application_runtime"]
  autoload :Client, lazy["client"]
  autoload :Command, lazy["command"]
  autoload :CommandOutputLimit, lazy["command"]
  autoload :CommandTimeout, lazy["command"]
  autoload :Dist, lazy["dist_config"]
  autoload :DistPackager, lazy["dist_packager"]
  autoload :Distribution, lazy["distribution"]
  autoload :FullRuntime, lazy["full_runtime"]
  autoload :Generator, lazy["generator"]
  autoload :Host, lazy["host"]
  autoload :LiteRuntime, lazy["lite_runtime"]
  autoload :LiteSource, lazy["lite_source"]
  autoload :LockedGems, lazy["locked_gems"]
  autoload :MacOSArchitecture, lazy["macos_architecture"]
  autoload :MacOSBundleSeal, lazy["macos_bundle_seal"]
  autoload :MacOSQmlPayload, lazy["macos_qml_payload"]
  autoload :Mobile, lazy["mobile"]
  autoload :PEDependencies, lazy["pe_dependencies"]
  autoload :Platform, lazy["platform"]
  autoload :QtBundleConfiguration, lazy["qt_bundle_configuration"]
  autoload :ReproducibleBuild, lazy["reproducible_build"]
  autoload :RubyRuntimeShaker, lazy["ruby_runtime_shaker"]
  autoload :Runner, lazy["runner"]
  autoload :Runtime, lazy["runtime"]
  autoload :SourceBundle, lazy["source_bundle"]
  autoload :TreeShaker, lazy["tree_shaker"]
end
