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

# A QML module the framework imports but the client omits fails to load at run
# time, which is exactly the silent fallback the framework forbids elsewhere.
# QtCharts and QtGraphs back the real Qt chart and GPU graph components, so the
# audit treats them like QtQuick.Controls: shippable payload, not optional.
required_qml_plugins = {
  "QtQuick/Controls" => %w[libqtquickcontrols2plugin.dylib qtquickcontrols2plugin.dll
                           libqtquickcontrols2plugin.so],
  "QtCharts" => %w[libqtchartsqml2plugin.dylib qtchartsqml2plugin.dll libqtchartsqml2plugin.so],
  "QtGraphs" => %w[libgraphsplugin.dylib graphsplugin.dll libgraphsplugin.so]
}
platform_index = if File.basename(archive).include?("macos")
                   0
                 elsif File.basename(archive).include?("windows")
                   1
                 else
                   2
                 end
qml_prefix = platform_index.zero? ? "zui-host.app/Contents/Resources/qml" : "qml"
required_qml_plugins.each do |qml_module, plugins|
  plugin = "#{qml_prefix}/#{qml_module}/#{plugins.fetch(platform_index)}"
  abort "client archive cannot load #{qml_module.tr('/', '.')}: #{plugin} is missing" unless entries.include?(plugin)
end

if File.basename(archive).include?("linux")
  %w[libicui18n libicuuc libicudata].each do |library|
    present = entries.any? { |entry| entry.match?(%r{\Alib/#{library}\.so(?:\.|\z)}) }
    abort "Linux client is missing private runtime dependency: #{library}" unless present
  end
end

puts format("Client audit passed: %.1f MiB, %d entries, desktop payload only.",
            size.fdiv(1024 * 1024), entries.length)
