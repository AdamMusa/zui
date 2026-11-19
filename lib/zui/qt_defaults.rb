# frozen_string_literal: true

require "json"
require "set"
require "tmpdir"

module Zui
  # Reads the real default value of every Qt property an adapter assigns.
  #
  # Qt's documented defaults and Qt's actual defaults disagree often enough to have produced
  # shipped bugs: `Gravity` documents no default but reports magnitude -10 and angle 90,
  # `Attractor` falls off `Linear` rather than `Constant`, and the sprite `frameRate` and
  # `frameDuration` use -2 as an "unset" sentinel rather than 0. The type descriptions in the SDK
  # carry no defaults at all, so the only source of truth is a live QML engine: this class
  # instantiates each type offscreen with `qml` and reads the values back.
  #
  # `rake qt:defaults` prints them next to the fallback the adapter declares, which is the check an
  # author otherwise has to do by hand for every property of a new component.
  class QtDefaults
    # Properties that describe the item rather than the component's behaviour; an adapter binds
    # them to the node's own geometry and is expected to differ from Qt.
    GEOMETRY_PROPERTIES = %w[
      x y z width height implicitWidth implicitHeight visible enabled opacity scale rotation
      anchors parent clip
    ].freeze

    Assignment = Struct.new(:source, :element, :qt_property, :zui_property, :fallback, :ambiguous,
                            keyword_init: true) do
      def geometry? = GEOMETRY_PROPERTIES.include?(qt_property)
    end

    Finding = Struct.new(:assignment, :qt_default, keyword_init: true) do
      def source = assignment.source
      def element = assignment.element
      def qt_property = assignment.qt_property
      def declared = assignment.fallback

      def differs?
        return false if qt_default.nil?

        normalize(declared) != normalize(qt_default)
      end

      def normalize(value)
        text = value.to_s.strip.delete_prefix('"').delete_suffix('"')
        return format("%g", Float(text)) if text.match?(/\A-?\d+(?:\.\d+)?\z/)

        text.downcase
      end
    end

    # Modules whose plugin could not be instantiated offscreen, so their defaults are unknown.
    attr_reader :warnings

    def initialize(qt_root:, framework_root: FRAMEWORK_ROOT, command: Command)
      @qt_root = File.expand_path(qt_root)
      @framework_root = File.expand_path(framework_root)
      @command = command
      @warnings = []
    end

    # The adapters of the framework, or the ones whose file name contains `filter`.
    def adapter_paths(filter = nil)
      paths = Dir[File.join(@framework_root, "Components", "Builtins", "**", "*.qml")].sort
      return paths unless filter

      paths.select { |path| File.basename(path, ".qml").downcase.include?(filter.downcase) }
    end

    # Every `qtProperty: … renderer.prop("zui_property", <literal>) …` assignment of an adapter,
    # attributed to the Qt element that encloses it.
    def assignments(paths)
      paths.flat_map { |path| parse(path) }
    end

    # The live default of every Qt property the assignments touch, as { element => { property => value } }.
    def live_defaults(assignments)
      wanted = assignments.reject(&:geometry?).each_with_object({}) do |assignment, types|
        (types[assignment.element] ||= Set.new) << assignment.qt_property
      end
      return {} if wanted.empty?

      probe(wanted)
    end

    def findings(paths)
      found = assignments(paths).reject(&:geometry?)
      defaults = live_defaults(found)
      found.map do |assignment|
        Finding.new(assignment:,
                    qt_default: defaults.dig(assignment.element, assignment.qt_property))
      end
    end

    private

    # QML in this framework is written compactly, with several properties and nested elements on one
    # line, so the parse walks the whole file in offset order rather than line by line: element
    # openers push onto a stack, closing braces pop it, and a property assignment belongs to
    # whatever element is on top.
    def parse(path)
      text = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
      source = path.delete_prefix("#{@framework_root}/")
      # Adapters import Qt Quick Controls and the framework's own directories under a qualifier, so
      # `QQC.Button` has to be resolved back to `QtQuick.Controls`; a qualifier that stands for a
      # framework directory rather than a Qt module resolves to nothing and is left alone.
      aliases = text.scan(/^\s*import\s+(?:"[^"]+"|([A-Z][\w.]*))\s+as\s+([A-Z]\w*)/)
                    .to_h { |qml_module, qualifier| [qualifier, qml_module] }
      stack = []
      assignments = []
      # A property value stops at the first `;`, line break or nested element, so an element the
      # value declares - `velocity: AngleDirection { angle: … }` - stays in the token stream and
      # the properties inside it are attributed to it rather than to the element around it.
      tokens = text.to_enum(
        :scan,
        /([A-Z][A-Za-z0-9_.]*)\s*\{|\{|\}|([a-zA-Z][\w.]*)\s*:\s*((?:(?![A-Z][A-Za-z0-9_.]*\s*\{)[^;\n{])*)/
      )
      tokens.each do
        match = Regexp.last_match
        if match[1]
          stack.push(resolve(match[1], aliases))
        elsif match[0] == "{"
          stack.push(stack.last)
        elsif match[0] == "}"
          stack.pop
        elsif match[2] && stack.last
          properties = match[3].scan(/renderer\.prop\(\s*"(\w+)"\s*,\s*("(?:[^"\\]|\\.)*"|[-\w.]+)\s*\)/)
          next if properties.empty?

          assignments << Assignment.new(
            source:, element: stack.last, qt_property: match[2], zui_property: properties.first[0],
            fallback: properties.first[1], ambiguous: properties.length > 1
          )
        end
      end
      assignments
    end

    # `QQC.Button` is `QtQuick.Controls`' Button; a qualifier bound to a directory import belongs
    # to the framework and keeps its qualified name, which marks it as not a Qt type.
    def resolve(element, aliases)
      qualifier, _, type = element.rpartition(".")
      return element if qualifier.empty?

      qml_module = aliases[qualifier]
      qml_module ? "#{qml_module}/#{type}" : element
    end

    # Instantiates the elements in an offscreen QML engine and reads the requested property values
    # back. One run per Qt module keeps a module whose plugin cannot load - Qt Quick 3D needs a
    # real GPU context - from taking the other modules' values with it, and a module that fails as
    # a group is retried element by element so one unprobeable type does not hide the rest.
    def probe(wanted)
      @warnings = []
      wanted.group_by { |element, _properties| module_of(element) }
            .each_with_object({}) do |(qml_module, group), defaults|
        next @warnings << "not a Qt type: #{group.map(&:first).sort.join(', ')}" if qml_module.nil?

        values = probe_module(qml_module, group.to_h)
        next defaults.merge!(values) if values

        group.each do |element, properties|
          single = probe_module(qml_module, { element => properties })
          single ? defaults.merge!(single) : @warnings << "#{element} (#{qml_module}) could not be instantiated offscreen"
        end
      end
    end

    def probe_module(qml_module, wanted)
      imports = ["QtQuick", qml_module].uniq
      Dir.mktmpdir("zui-qt-defaults-") do |directory|
        path = File.join(directory, "Probe.qml")
        File.write(path, probe_source(wanted, imports))
        result = @command.run([File.join(@qt_root, "bin", "qml"), path],
                              env: { "QT_QPA_PLATFORM" => "offscreen" },
                              timeout: 30, max_output_bytes: 8_000_000)
        # `qml` writes console.log to stderr, alongside the platform plugin's own warnings.
        payload = "#{result.stdout}\n#{result.stderr}".lines
                                                      .filter_map { |line| line[/\Aqml: (\{.*\})\s*\z/, 1] }.last
        payload && JSON.parse(payload)
      end
    rescue JSON::ParserError, CommandTimeout, CommandOutputLimit, Errno::ENOENT
      # A module whose types open a window, need a real GPU context or never reach
      # Component.onCompleted leaves the engine running; its defaults stay unknown.
      nil
    end

    # An element the parse resolved through an import alias already names its module.
    def module_of(element)
      qml_module, separator, _type = element.rpartition("/")
      return qml_module unless separator.empty?

      @module_of ||= begin
        report = QtCoverageReport.new(qt_root: @qt_root, framework_root: @framework_root)
        imported = framework_imports
        report.declared_types.select { |name, _types| imported.include?(name) }
              .each_with_object({}) do |(name, types), index|
          types.each { |type| index[type] ||= name }
        end
      end
      @module_of[element]
    end

    def probe_source(wanted, imports)
      instances = wanted.keys.each_with_index.map do |element, index|
        "  #{element.split('/').last} { id: probe#{index} }"
      end
      reads = wanted.each_with_index.map do |(element, properties), index|
        fields = properties.to_a.sort.map do |property|
          "\"#{property}\": describe(probe#{index}.#{property})"
        end
        "    \"#{element}\": { #{fields.join(', ')} }"
      end
      <<~QML
        #{imports.map { |name| "import #{name}" }.join("\n")}

        Item {
          function describe(value) {
            if (value === null || value === undefined) return null
            if (typeof value === "object") return String(value)
            return value
          }
        #{instances.join("\n")}
          Component.onCompleted: {
            console.log(JSON.stringify({
        #{reads.join(",\n")}
            }))
            Qt.exit(0)
          }
        }
      QML
    end

    # The adapters' own imports, so a probe resolves the same types they do.
    def framework_imports
      QtModules.imported_by(@framework_root).keys
               .select { |name| name.match?(/\A(?:QML|Qt)/) }
               .reject { |name| name.start_with?("QtQuick.Controls.") }
               .sort
    end
  end
end
