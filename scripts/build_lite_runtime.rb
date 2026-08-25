# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require_relative "../lib/zui"
require_relative "../lib/zui/lite_runtime_packager"

root = File.expand_path("..", __dir__)
mruby_source = File.expand_path(ARGV.fetch(0) do
  abort "Usage: build_lite_runtime.rb MRUBY_SOURCE MRUBY_JSON_SOURCE [OUTPUT]"
end)
json_source = File.expand_path(ARGV.fetch(1) do
  abort "Usage: build_lite_runtime.rb MRUBY_SOURCE MRUBY_JSON_SOURCE [OUTPUT]"
end)
output = File.expand_path(ARGV.fetch(2, File.join(root, "tmp", "runtimes")))

abort "mruby source is missing: #{mruby_source}" unless File.file?(File.join(mruby_source, "Rakefile"))
abort "mruby-json source is missing: #{json_source}" unless File.file?(File.join(json_source, "mrbgem.rake"))

environment = {
  "MRUBY_CONFIG" => File.join(root, "runtime", "mruby", "build_config.rb"),
  "ZUI_MRUBY_JSON" => json_source
}
success = system(environment, RbConfig.ruby, "-S", "rake", "-j2", chdir: mruby_source)
abort "mruby build failed" unless success

name = Zui::Platform.current.windows? ? "mruby.exe" : "mruby"
executable = File.join(mruby_source, "build", "zui", "bin", name)
archive = Zui::LiteRuntimePackager.new.package(executable:, output:)
puts archive
