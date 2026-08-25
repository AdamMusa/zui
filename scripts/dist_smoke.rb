# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "tmpdir"
require "zlib"

archive = File.expand_path(ARGV.fetch(0) { abort "Usage: dist_smoke.rb CLIENT.tar.gz ZUI_CLI" })
cli = File.expand_path(ARGV.fetch(1) { abort "Usage: dist_smoke.rb CLIENT.tar.gz ZUI_CLI" })
abort "client archive is missing: #{archive}" unless File.file?(archive)
abort "client checksum is missing: #{archive}.sha256" unless File.file?("#{archive}.sha256")
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
  output = File.join(directory, "release")
  cache = File.join(directory, "cache")
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

  environment = {
    "ZUI_CACHE_HOME" => cache,
    "ZUI_CLIENT_ARCHIVE" => archive,
    "ZUI_CLIENT_CHECKSUM" => "#{archive}.sha256"
  }
  abort "distribution smoke could not configure the native client" unless system(
    environment, RbConfig.ruby, cli, "doctor", "--fix"
  )
  abort "zui bundle --dist failed" unless system(
    { "ZUI_CACHE_HOME" => cache }, RbConfig.ruby, cli, "bundle", "--dist", "--output", output, project
  )

  artifacts = Dir[File.join(output, "*")].sort
  expected_extensions = if RUBY_PLATFORM.match?(/darwin/i)
                          %w[.dmg]
                        elsif RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
                          %w[.exe]
                        else
                          %w[.deb .rpm]
                        end
  actual_extensions = artifacts.map { |path| File.extname(path) }.sort
  abort "unexpected distribution artifacts: #{artifacts.inspect}" unless actual_extensions == expected_extensions.sort
  artifacts.each { |path| abort "empty distribution artifact: #{path}" unless File.size(path).positive? }

  if expected_extensions.include?(".deb")
    deb = artifacts.find { |path| path.end_with?(".deb") }
    rpm = artifacts.find { |path| path.end_with?(".rpm") }
    abort "invalid DEB header" unless File.binread(deb, 8) == "!<arch>\n"
    abort "invalid RPM header" unless File.binread(rpm, 4) == "\xed\xab\xee\xdb".b
  elsif expected_extensions == [".exe"]
    abort "invalid setup executable" unless File.binread(artifacts.first, 2) == "MZ"
  else
    trailer = File.binread(artifacts.first, 512, [File.size(artifacts.first) - 512, 0].max)
    abort "invalid DMG trailer" unless trailer.include?("koly")
  end
end

puts "Zui native distribution smoke passed."
