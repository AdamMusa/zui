# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "rubygems"
require_relative "../lib/zui"

ROOT = File.expand_path("..", __dir__)

def run!(*arguments)
  puts "+ #{arguments.join(' ')}"
  success = system(*arguments, chdir: ROOT)
  abort "command failed: #{arguments.first}" unless success
end

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

platform = Zui::Platform.current.assert_supported!
executable_name = platform.windows? ? "zui-host.exe" : "zui-host"
host_path = File.join(ROOT, "tmp", "ci-host", platform.id, executable_name)
FileUtils.rm_f(host_path)
puts "+ build native host for #{platform.id}"
Zui::Host.new(platform:).build!(host_path)
abort "native host was not produced: #{host_path}" unless File.executable?(host_path)

gem_dir = File.join(ROOT, "tmp", "gems")
FileUtils.mkdir_p(gem_dir)
gem_path = File.join(gem_dir, "zui-#{Zui::VERSION}.gem")
FileUtils.rm_f(gem_path)
run!(RbConfig.ruby, "-S", "gem", "build", "zui.gemspec", "--output", gem_path)
run!(RbConfig.ruby, "-S", "gem", "install", "--local", "--force", "--no-document", gem_path)
cli_path = Gem.bin_path("zui", "zui", Zui::VERSION)
run!(RbConfig.ruby, cli_path, "version")
run!(RbConfig.ruby, File.join(ROOT, "scripts", "runtime_smoke.rb"), host_path, cli_path,
     File.join(ROOT, "test", "fixtures", "smoke_app.rb"))

puts "Zui native CI passed on #{platform.id}."
