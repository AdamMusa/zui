# frozen_string_literal: true

namespace :qt do
  desc "Regenerate docs/qt-coverage.md from the registry, the mobile catalog and the Qt host SDK"
  task :coverage do
    $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
    require "zui"

    root = ENV["ZUI_QT_HOST"]
    abort("set ZUI_QT_HOST to the installed Qt host SDK root") if root.to_s.empty?
    abort("no Qt QML modules under #{File.join(root, 'qml')}") unless File.directory?(File.join(root, "qml"))

    report = Zui::QtCoverageReport.new(qt_root: root)
    path = report.write!
    puts "Wrote #{report.covered.size} covered Qt types (#{report.aliases.size} renamed) to #{path}"
  end
end
