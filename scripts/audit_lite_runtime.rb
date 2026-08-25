# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "tmpdir"
require_relative "../lib/zui"

archive = File.expand_path(ARGV.fetch(0) { abort "Usage: audit_lite_runtime.rb ARCHIVE.tar.gz" })
abort "lite runtime archive is missing: #{archive}" unless File.file?(archive)
abort "lite runtime checksum is missing: #{archive}.sha256" unless File.file?("#{archive}.sha256")

Dir.mktmpdir("zui-lite-runtime-audit-") do |directory|
  runtime = Zui::LiteRuntime.new(
    cache_root: File.join(directory, "cache"),
    environment: {
      "ZUI_LITE_RUNTIME_ARCHIVE" => archive,
      "ZUI_LITE_RUNTIME_CHECKSUM" => "#{archive}.sha256"
    }
  )
  runtime.configure!
  abort "installed lite runtime did not validate" unless runtime.configured?
  executable = File.join(runtime.root, runtime.manifest.fetch("executable"))
  output, error, status = Open3.capture3(executable, "-v")
  abort "installed lite runtime could not execute: #{error}" unless status.success?
  expected = "mruby #{Zui::LiteRuntime::MRUBY_VERSION}"
  abort "unexpected lite runtime version: #{output.inspect}" unless output.include?(expected)
end

puts "Zui lite runtime archive passed checksum, manifest, and execution checks."
