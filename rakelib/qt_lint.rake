# frozen_string_literal: true

namespace :qt do
  # qmllint resolves QML against real Qt type data, so it reports an unknown member or an
  # unresolvable type that neither `rake test` nor a host build can see. Its categories cannot be
  # raised to errors in Qt 6.8, so this task prints the findings, summarises them per category and
  # fails only on the type-resolution categories, and only when asked.
  desc "Run qmllint over the framework QML against the pinned Qt SDK (ZUI_QT_HOST)"
  task :lint, [:paths] do |_task, arguments|
    root = File.expand_path("..", __dir__)
    $LOAD_PATH.unshift(File.join(root, "lib"))
    require "zui"

    qt = ENV["ZUI_QT_HOST"] ||
         File.join(root, "tmp", "Qt", Zui::Mobile::Setup::QT_VERSION, "macos")
    linter = File.join(qt, "bin", "qmllint")
    unless File.executable?(linter)
      abort("qmllint not found at #{linter}; set ZUI_QT_HOST to an installed Qt SDK " \
            "or run `zui mobile --fix`")
    end

    # Categories that report Qt's own incomplete type data or a framework convention rather than a
    # fault: the Theme singleton is exported as a plain QObject, adapters read `renderer` from the
    # element that loads them, and an adapter imports the module its component documents even when
    # its QML names no type from it.
    advisory = %w[unqualified unused-imports required missing-property]
    # The categories worth stopping for: an adapter that names a type the pinned Qt cannot provide
    # shows up here. ZUI_QMLLINT_STRICT=1 turns them into a failure.
    significant = %w[missing-type unresolved-type incompatible-type import]

    paths =
      if arguments[:paths]
        arguments[:paths].split(":").flat_map do |path|
          File.directory?(path) ? Dir[File.join(path, "**", "*.qml")] : path
        end
      else
        %w[Components Controls Theme].flat_map { |directory| Dir[File.join(root, directory, "**", "*.qml")] } +
          Dir[File.join(root, "*.qml")]
      end
    abort("no QML to lint") if paths.empty?

    command = [linter, "-I", File.join(qt, "qml"), "-I", root]
    command.concat(advisory.flat_map { |category| ["--#{category}", "disable"] })
    command.concat(paths.sort)
    puts "qmllint: #{paths.size} files against the Qt SDK in #{qt}"
    puts "advisory categories disabled: #{advisory.join(', ')}"

    output = IO.popen(command, err: [:child, :out], &:read)
    status = $?
    puts output
    counts = output.scan(/\[([A-Za-z][\w.-]*)\]\s*$/).flatten.tally.sort_by { |_name, count| -count }
    if counts.empty?
      puts "qmllint reported nothing in the enabled categories"
    else
      puts "findings by category:"
      counts.each { |name, count| puts format("  %-32s %d", name, count) }
    end
    abort("qmllint failed") unless status.success?

    raised = counts.select { |name, _count| significant.include?(name) }
    if raised.empty?
      puts "no type-resolution findings"
    elsif ENV["ZUI_QMLLINT_STRICT"].to_s.empty?
      puts "set ZUI_QMLLINT_STRICT=1 to fail on #{significant.join(', ')}"
    else
      abort("qmllint reported #{raised.map { |name, count| "#{count} #{name}" }.join(', ')}")
    end
  end
end
