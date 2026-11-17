# frozen_string_literal: true

require "json"

namespace :qt do
  # The release audit enforces 100 MiB on the compressed client archive, which is only measurable
  # after a Linux client build. Nobody adding a Qt module can see what it costs, and several tracks
  # have been adding modules at once, so the uncompressed payload of each QML root is recorded in
  # native/qt-payload-budget.json: adding a module shows up as a diff to that file, and the test
  # fails when the recorded total crosses the budget.
  desc "Measure the client QML payload per root; WRITE=1 records it in native/qt-payload-budget.json"
  task :payload do
    root = File.expand_path("..", __dir__)
    $LOAD_PATH.unshift(File.join(root, "lib"))
    require "zui"
    require "zui/client_payload"

    qt = ENV["ZUI_QT_HOST"] || File.join(root, "tmp", "Qt", Zui::Mobile::Setup::QT_VERSION, "macos")
    qml = File.join(qt, "qml")
    abort("no Qt QML tree at #{qml}; set ZUI_QT_HOST") unless File.directory?(qml)

    payload = Zui::ClientPayload
    measured = payload.measure(qml)
    recorded = payload.budget.fetch("roots")
    budget = payload.budget_bytes

    puts format("%-18s %10s %10s  %s", "root", "measured", "recorded", "modules")
    measured.sort_by { |_name, bytes| -bytes }.each do |name, bytes|
      puts format(
        "%-18s %9.1fM %9.1fM  %s", name, bytes / 1048576.0,
        recorded.fetch(name, 0) / 1048576.0, payload.modules_in_root(name).join(" ")
      )
    end
    total = measured.values.sum
    puts format("%-18s %9.1fM %9.1fM", "TOTAL", total / 1048576.0, payload.recorded_bytes / 1048576.0)
    puts format("budget %.1fM, %.1fM left (%.0f%% used)", budget / 1048576.0,
                (budget - total) / 1048576.0, total * 100.0 / budget)
    puts "measured on #{payload.budget.fetch('measured_on')}"

    unrecorded = measured.keys - recorded.keys
    puts "not recorded yet: #{unrecorded.join(', ')}" unless unrecorded.empty?

    if ENV["WRITE"].to_s.empty?
      puts "run with WRITE=1 to record this measurement"
    else
      document = payload.budget.merge(
        "roots" => measured.sort.to_h,
        "total_bytes" => total,
        "measured_at" => Time.now.utc.strftime("%Y-%m-%d")
      )
      File.write(Zui::ClientPayload::BUDGET_PATH, "#{JSON.pretty_generate(document)}\n")
      puts "recorded #{measured.size} roots in #{Zui::ClientPayload::BUDGET_PATH}"
    end
    abort("payload exceeds its budget by #{(total - budget) / 1048576} MiB") if total > budget
  end
end
