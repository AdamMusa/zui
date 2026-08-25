# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "rubygems"
require_relative "../lib/zui"
require_relative "../lib/zui/client_builder"

ROOT = File.expand_path("..", __dir__)

def run!(*arguments)
  puts "+ #{arguments.join(' ')}"
  success = system(*arguments, chdir: ROOT)
  abort "command failed: #{arguments.first}" unless success
end

platform = Zui::Platform.current.assert_supported!
mruby_source = File.expand_path(ENV.fetch("ZUI_MRUBY_SOURCE", File.join(ROOT, "tmp", "mruby")))
json_source = File.expand_path(ENV.fetch("ZUI_MRUBY_JSON_SOURCE", File.join(ROOT, "tmp", "mruby-json")))
abort "pinned mruby source is missing: #{mruby_source}" unless File.file?(File.join(mruby_source, "Rakefile"))
abort "pinned mruby-json source is missing: #{json_source}" unless File.file?(File.join(json_source, "mrbgem.rake"))

runtime_dir = File.join(ROOT, "tmp", "runtimes")
FileUtils.mkdir_p(runtime_dir)
lite_archive = File.join(runtime_dir, "zui-runtime-lite-#{platform.id}.tar.gz")
FileUtils.rm_f([lite_archive, "#{lite_archive}.sha256"])
run!(RbConfig.ruby, File.join(ROOT, "scripts", "build_lite_runtime.rb"),
     mruby_source, json_source, runtime_dir)
run!(RbConfig.ruby, File.join(ROOT, "scripts", "audit_lite_runtime.rb"), lite_archive)
mruby_name = platform.windows? ? "mruby.exe" : "mruby"
ENV["ZUI_MRUBY"] = File.join(mruby_source, "build", "zui", "bin", mruby_name)

test_files = Dir[File.join(ROOT, "test", "*_test.rb"),
                 File.join(ROOT, "examples", "*", "test", "*_test.rb")].sort
test_files.each { |file| run!(RbConfig.ruby, "-I#{File.join(ROOT, 'lib')}", file) }

qml_linter = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).filter_map do |directory|
  %w[qmllint qmllint.exe].map { |name| File.join(directory, name) }.find { |path| File.executable?(path) }
end.first
abort "qmllint was not installed by the Qt setup" unless qml_linter
qml_files = %w[Desktop.qml Service.qml ControlNode.qml].map { |name| File.join(ROOT, name) }
qml_files.concat(Dir[File.join(ROOT, "{Components,Controls,Theme}", "**", "*.qml")].sort)
qml_files.each_slice(40) { |files| run!(qml_linter, "-I", ROOT, *files) }

client_dir = File.join(ROOT, "tmp", "clients")
FileUtils.mkdir_p(client_dir)
Dir[File.join(client_dir, "zui-client-#{platform.id}.tar.gz*")].each { |path| FileUtils.rm_f(path) }
puts "+ build relocatable client for #{platform.id}"
client_archive = Zui::ClientBuilder.new(platform:).build!(output: client_dir)
run!(RbConfig.ruby, File.join(ROOT, "scripts", "audit_client.rb"), client_archive)

gem_dir = File.join(ROOT, "tmp", "gems")
FileUtils.mkdir_p(gem_dir)
gem_path = File.join(gem_dir, "zui-#{Zui::VERSION}.gem")
FileUtils.rm_f(gem_path)
run!(RbConfig.ruby, "-S", "gem", "build", "zui.gemspec", "--output", gem_path)
run!(RbConfig.ruby, "-S", "gem", "install", "--local", "--force", "--no-document", gem_path)
cli_path = Gem.bin_path("zui", "zui", Zui::VERSION)
run!(RbConfig.ruby, cli_path, "version")
run!(RbConfig.ruby, File.join(ROOT, "scripts", "client_smoke.rb"), client_archive, lite_archive, cli_path,
     File.join(ROOT, "test", "fixtures", "smoke_app.rb"))
run!(RbConfig.ruby, File.join(ROOT, "scripts", "runtime_modes_smoke.rb"),
     client_archive, lite_archive, cli_path, File.join(ROOT, "test", "fixtures", "smoke_app.rb"))
run!(RbConfig.ruby, File.join(ROOT, "scripts", "dist_smoke.rb"), client_archive, lite_archive, cli_path)

puts "Zui native CI passed on #{platform.id}."
