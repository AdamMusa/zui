# frozen_string_literal: true

require "json"

namespace :qt do
  desc "Regenerate native/qt-modules.json from installed Qt SDKs (ZUI_QT_HOST, ZUI_QT_IOS, ZUI_QT_ANDROID)"
  task :modules do
    $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
    require "zui"

    roots = {
      "host" => ENV["ZUI_QT_HOST"],
      "ios" => ENV["ZUI_QT_IOS"],
      "android" => ENV["ZUI_QT_ANDROID"]
    }.compact.reject { |_target, path| path.to_s.empty? }
    missing = %w[host ios android] - roots.keys
    unless missing.empty?
      abort("set #{missing.map { |target| "ZUI_QT_#{target.upcase}" }.join(', ')} to the installed Qt SDK roots")
    end
    unreadable = roots.reject { |_target, path| File.directory?(File.join(path, "qml")) }
    unless unreadable.empty?
      abort("no Qt QML modules under #{unreadable.values.map { |path| File.join(path, 'qml') }.join(', ')}")
    end

    document = Zui::QtModules::SdkScan.new(roots).document
    overrides_path = File.expand_path("../native/qt-modules.overrides.json", __dir__)
    overrides = File.file?(overrides_path) ? JSON.parse(File.read(overrides_path)) : {}
    document["modules"] = document.fetch("modules").map do |entry|
      entry.merge(overrides.fetch(entry.fetch("qml_module"), {}))
    end
    File.write(Zui::QtModules.registry_path, "#{JSON.pretty_generate(document)}\n")
    puts "Wrote #{document.fetch('modules').size} Qt QML modules to #{Zui::QtModules.registry_path}"
  end
end
