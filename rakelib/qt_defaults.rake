# frozen_string_literal: true

namespace :qt do
  # Qt's documented defaults and Qt's real defaults disagree often enough to have shipped bugs, and
  # the SDK's type descriptions carry no defaults at all, so the only source of truth is a live QML
  # engine. This reads them back offscreen and prints them next to the fallback each adapter
  # declares, which is otherwise a by-hand check for every property of a new component.
  desc "Compare adapter property fallbacks with the real Qt defaults (ZUI_QT_HOST, optional adapter filter)"
  task :defaults, [:adapter] do |_task, arguments|
    root = File.expand_path("..", __dir__)
    $LOAD_PATH.unshift(File.join(root, "lib"))
    require "zui"
    require "zui/qt_defaults"

    qt = ENV["ZUI_QT_HOST"] || File.join(root, "tmp", "Qt", Zui::Mobile::Setup::QT_VERSION, "macos")
    unless File.executable?(File.join(qt, "bin", "qml"))
      abort("no qml runtime at #{File.join(qt, 'bin', 'qml')}; set ZUI_QT_HOST or run `zui mobile --fix`")
    end

    defaults = Zui::QtDefaults.new(qt_root: qt, framework_root: root)
    paths = defaults.adapter_paths(arguments[:adapter])
    abort("no adapter matches #{arguments[:adapter].inspect}") if paths.empty?

    findings = defaults.findings(paths)
    differing = findings.select(&:differs?)
    puts "#{paths.length} adapter(s), #{findings.length} Qt property assignments, " \
         "#{differing.length} differ from the Qt default"
    defaults.warnings.each { |warning| puts "warning: #{warning}" }
    puts
    puts format("%-34s %-18s %-26s %-18s %-18s", "adapter", "element", "property", "zui fallback", "qt default")
    findings.sort_by { |finding| [finding.source, finding.element, finding.qt_property] }.each do |finding|
      next if ENV["ZUI_QT_DEFAULTS_ALL"].to_s.empty? && !finding.differs?

      puts format(
        "%-34s %-18s %-26s %-18s %-18s%s",
        File.basename(finding.source), finding.element, finding.qt_property,
        finding.declared, finding.qt_default.nil? ? "null or absent" : finding.qt_default.to_s,
        finding.assignment.ambiguous ? "  (line sets several properties)" : ""
      )
    end
    puts
    puts "Only differing properties are listed; set ZUI_QT_DEFAULTS_ALL=1 for every assignment."
    puts "A difference is not automatically wrong: Zui chooses its own defaults. It is wrong when " \
         "the adapter meant to keep Qt's."
  end
end
