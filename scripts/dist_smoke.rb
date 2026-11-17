# frozen_string_literal: true

require "digest"
require "fileutils"
require "rbconfig"
require "tmpdir"
require "zlib"
require_relative "../lib/zui"

archive = File.expand_path(ARGV.fetch(0) { abort "Usage: dist_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI" })
lite_archive = File.expand_path(ARGV.fetch(1) { abort "Usage: dist_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI" })
cli = File.expand_path(ARGV.fetch(2) { abort "Usage: dist_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI" })
abort "client archive is missing: #{archive}" unless File.file?(archive)
abort "client checksum is missing: #{archive}.sha256" unless File.file?("#{archive}.sha256")
abort "lite runtime archive is missing: #{lite_archive}" unless File.file?(lite_archive)
abort "lite runtime checksum is missing: #{lite_archive}.sha256" unless File.file?("#{lite_archive}.sha256")
abort "installed Zui CLI is missing: #{cli}" unless File.file?(cli)

def png_chunk(type, data)
  [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
end

def release_png
  width = height = 256
  scanlines = Array.new(height) { "\0" + ([38, 122, 255, 255].pack("C4") * width) }.join
  "\x89PNG\r\n\x1a\n".b +
    png_chunk("IHDR", [width, height, 8, 6, 0, 0, 0].pack("NNC5")) +
    png_chunk("IDAT", Zlib.deflate(scanlines, Zlib::BEST_COMPRESSION)) +
    png_chunk("IEND", "")
end

def write_icons(directory)
  png = release_png
  File.binwrite(File.join(directory, "icon.png"), png)
  ico_header = [0, 1, 1].pack("v3")
  ico_entry = [0, 0, 0, 0, 1, 32, png.bytesize, 22].pack("C4v2V2")
  File.binwrite(File.join(directory, "icon.ico"), ico_header + ico_entry + png)
  icns_element = "ic08" + [png.bytesize + 8].pack("N") + png
  File.binwrite(File.join(directory, "icon.icns"), "icns" + [icns_element.bytesize + 8].pack("N") + icns_element)
end

Dir.mktmpdir("zui-dist-smoke-") do |directory|
  project = File.join(directory, "project")
  assets = File.join(project, "assets")
  outputs = %w[first second].map { |name| File.join(directory, "release-#{name}") }
  cache = File.join(directory, "cache")
  epoch = Zui::ReproducibleBuild::DEFAULT_EPOCH
  FileUtils.mkdir_p(assets)
  File.write(File.join(project, "main.rb"), <<~RUBY)
    require "zui"
    Zui.app { app(title: "Distribution Smoke") { text "release ready" } }
  RUBY
  write_icons(assets)
  File.write(File.join(project, "config.rb"), <<~RUBY)
    Zui::Dist.configure do
      name "Zui Distribution Smoke"
      identifier "dev.zui.distribution-smoke"
      version "1.0.0"
      publisher "Zui CI <ci@example.com>"
      description "Zui native installer verification."
      license "MIT"
      icon linux: "assets/icon.png", macos: "assets/icon.icns", windows: "assets/icon.ico"
      categories "Utility"
    end
  RUBY
  File.write(File.join(project, "Gemfile"), <<~RUBY)
    source "https://rubygems.org"
    gem "zui", path: #{Zui::FRAMEWORK_ROOT.dump}
  RUBY
  lock_environment = { "BUNDLE_GEMFILE" => File.join(project, "Gemfile") }
  abort "could not lock the distribution smoke Gemfile" unless system(
    lock_environment, RbConfig.ruby, "-S", "bundle", "lock", "--local", chdir: project
  )

  environment = {
    "ZUI_CACHE_HOME" => cache,
    "ZUI_CLIENT_ARCHIVE" => archive,
    "ZUI_CLIENT_CHECKSUM" => "#{archive}.sha256",
    "ZUI_LITE_RUNTIME_ARCHIVE" => lite_archive,
    "ZUI_LITE_RUNTIME_CHECKSUM" => "#{lite_archive}.sha256",
    "SOURCE_DATE_EPOCH" => epoch.to_s
  }
  abort "distribution smoke could not configure the native client" unless system(
    environment, RbConfig.ruby, cli, "doctor", "--fix"
  )
  expected_extensions = if RUBY_PLATFORM.match?(/darwin/i)
                          %w[.dmg]
                        elsif RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
                          %w[.exe]
                        else
                          %w[.deb .rpm]
                        end
  artifact_sets = outputs.each_with_index.map do |output, index|
    changed_time = Time.at(epoch + index + 1).utc
    File.utime(changed_time, changed_time, File.join(project, "main.rb"))
    abort "zui bundle --dist --full failed on pass #{index + 1}" unless system(
      { "ZUI_CACHE_HOME" => cache, "SOURCE_DATE_EPOCH" => epoch.to_s },
      RbConfig.ruby, cli, "bundle", "--dist", "--full", "--output", output, project
    )

    artifacts = Dir[File.join(output, "*")].sort
    actual_extensions = artifacts.map { |path| File.extname(path) }.sort
    unless actual_extensions == expected_extensions.sort
      abort "unexpected distribution artifacts on pass #{index + 1}: #{artifacts.inspect}"
    end
    artifacts.each { |path| abort "empty distribution artifact: #{path}" unless File.size(path).positive? }
    artifacts
  end

  first_artifacts, second_artifacts = artifact_sets
  first_names = first_artifacts.map { |path| File.basename(path) }
  second_names = second_artifacts.map { |path| File.basename(path) }
  abort "distribution artifact names changed between builds" unless first_names == second_names
  first_artifacts.zip(second_artifacts).each do |first, second|
    first_digest = Digest::SHA256.file(first).hexdigest
    second_digest = Digest::SHA256.file(second).hexdigest
    unless File.size(first) == File.size(second) && first_digest == second_digest && FileUtils.compare_file(first, second)
      abort "non-reproducible distribution artifact: #{File.basename(first)} " \
            "(#{first_digest} != #{second_digest})"
    end
    puts "Reproducible distribution: #{File.basename(first)} #{first_digest}"
  end

  if expected_extensions.include?(".deb")
    deb = first_artifacts.find { |path| path.end_with?(".deb") }
    rpm = first_artifacts.find { |path| path.end_with?(".rpm") }
    abort "invalid DEB header" unless File.binread(deb, 8) == "!<arch>\n"
    abort "invalid RPM header" unless File.binread(rpm, 4) == "\xed\xab\xee\xdb".b
  elsif expected_extensions == [".exe"]
    abort "invalid setup executable" unless File.binread(first_artifacts.first, 2) == "MZ"
  else
    trailer = File.binread(first_artifacts.first, 512, [File.size(first_artifacts.first) - 512, 0].max)
    abort "invalid DMG trailer" unless trailer.include?("koly")
  end
end

puts "Zui native distribution smoke passed."
