# frozen_string_literal: true

require "rubygems/package"
require "zlib"

archive = File.expand_path(ARGV.fetch(0) { abort "Usage: audit_client.rb CLIENT.tar.gz" })
abort "client archive is missing: #{archive}" unless File.file?(archive)

maximum_megabytes = Integer(ENV.fetch("ZUI_MAX_CLIENT_ARCHIVE_MB", "100"), 10)
maximum_bytes = maximum_megabytes * 1024 * 1024
size = File.size(archive)
if size > maximum_bytes
  abort format("client archive is %.1f MiB; budget is %d MiB", size.fdiv(1024 * 1024), maximum_megabytes)
end

forbidden = %r{
  (?:\A|/)(?:
    QtWebEngine[^/]*|QtWebChannel[^/]*|QtPositioning|qtwebengine[^/]*|(?:lib)?qwebengine[^/]*|
    webchannel[^/]*|(?:lib)?Qt6(?:WebEngine|WebChannel|Positioning)[^/]*|position|Quickshell|
    SddmComponents|Qt5Compat
  )(?:/|\z)|
  (?:\A|/)qml/org/|(?:\A|/)QtQuick/Pdf(?:/|\z)
}ix

entries = []
Zlib::GzipReader.open(archive) do |gzip|
  Gem::Package::TarReader.new(gzip) do |tar|
    tar.each { |entry| entries << entry.full_name.tr("\\", "/") }
  end
end

abort "client archive has no manifest" unless entries.include?("client.json")
offender = entries.find { |entry| entry.match?(forbidden) }
abort "client archive contains forbidden payload: #{offender}" if offender

controls_plugin = if File.basename(archive).include?("macos")
                    "zui-host.app/Contents/Resources/qml/QtQuick/Controls/libqtquickcontrols2plugin.dylib"
                  elsif File.basename(archive).include?("windows")
                    "qml/QtQuick/Controls/qtquickcontrols2plugin.dll"
                  else
                    "qml/QtQuick/Controls/libqtquickcontrols2plugin.so"
                  end
abort "client archive cannot load QtQuick.Controls: #{controls_plugin} is missing" unless entries.include?(controls_plugin)

if File.basename(archive).include?("linux")
  %w[libicui18n libicuuc libicudata].each do |library|
    present = entries.any? { |entry| entry.match?(%r{\Alib/#{library}\.so(?:\.|\z)}) }
    abort "Linux client is missing private runtime dependency: #{library}" unless present
  end
end

puts format("Client audit passed: %.1f MiB, %d entries, desktop payload only.",
            size.fdiv(1024 * 1024), entries.length)
