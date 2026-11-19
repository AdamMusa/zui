# frozen_string_literal: true

require "set"

module Zui
  # Generates docs/qt-coverage.md: every Qt QML module, every public type in it, and the Zui
  # component that covers it.
  #
  # Coverage is derived, never written down. A Qt type is covered when the framework imports the
  # module that declares it and either `Zui::Mobile::ComponentCatalog` maps the type to a registered
  # component, or the type's name in Ruby spelling is a registered component. The module list and
  # the mobile targets come from `Zui::QtModules`; the type lists are read from an installed Qt SDK,
  # which is why `rake qt:coverage` generates the document and the result is committed.
  class QtCoverageReport
    DOCUMENT_PATH = File.expand_path("../../docs/qt-coverage.md", __dir__)
    # Qt Quick Controls declares no types of its own; `import QtQuick.Controls` resolves them
    # through the default style.
    DEFAULT_STYLE = { "QtQuick.Controls" => "QtQuick.Controls.Basic" }.freeze
    # The other styles re-declare the same type names with a different look, so listing their types
    # would report the Controls catalog seven more times.
    STYLE_MODULE = /\AQtQuick\.Controls\.[A-Za-z]/
    INTERNAL_TYPE = /(?:Private|Specifics|Attached)\z/
    # Which Qt QML module each group of the mobile catalog describes. Qt reuses type names across
    # modules — `MessageDialog` exists in both `QtQuick.Dialogs` and `Qt.labs.platform`, and
    # `QtQuick.Templates` mirrors the whole Controls catalog — so a catalog entry is attributed to
    # the module its group describes rather than to every module declaring that name.
    CATALOG_MODULES = {
      QUICK_CONTROLS: %w[QtQuick.Controls],
      QUICK_DIALOGS: %w[QtQuick.Dialogs],
      QUICK_LAYOUTS: %w[QtQuick.Layouts],
      PERMISSIONS: %w[QtCore],
      DEVICE_INFORMATION: %w[QtCore QtNetwork],
      VIRTUAL_KEYBOARD: %w[QtQuick.VirtualKeyboard QtQuick.VirtualKeyboard.Settings],
      SENSORS: %w[QtSensors],
      POSITIONING: %w[QtPositioning],
      LOCATION: %w[QtLocation],
      TEXT_TO_SPEECH: %w[QtTextToSpeech],
      WEB: %w[QtWebView],
      WEB_SOCKETS: %w[QtWebSockets],
      LOTTIE: %w[Qt.labs.lottieqt],
      PDF: %w[QtQuick.Pdf],
      TOUCH_INTERACTION: %w[QtQuick]
    }.freeze
    # Groups that merge the others rather than describing a module of their own.
    CATALOG_AGGREGATES = %i[CORE ALL].freeze

    ModuleCoverage = Struct.new(:entry, :types, :style, :coverage, :imported, keyword_init: true) do
      def name = entry.qml_module
      def style? = style
      def imported? = imported
      def covered_types = types.select { |type| coverage.key?(type) }
      def uncovered_types = types - covered_types
      def components = covered_types.map { |type| coverage.fetch(type) }.uniq
    end

    def initialize(qt_root:, framework_root: FRAMEWORK_ROOT, modules: QtModules.all,
                   catalog: Mobile::ComponentCatalog, components: COMPONENTS)
      @qt_root = File.expand_path(qt_root)
      @catalog = catalog
      @components = components
      @framework_root = framework_root
      @registry = modules
    end

    def qt_version = QtModules.qt_version

    # Reading the Qt SDK is deferred so the alias table and the catalog checks work without one.
    def modules
      @modules ||= @registry.map { |entry| module_coverage(entry) }
    end

    # Every Qt type a Zui component renders, as { Qt type => component }.
    def covered
      @covered ||= modules.map(&:coverage).reduce({}, :merge)
    end

    # The catalog groups that describe one Qt QML module each, as { group name => mapping }.
    def catalog_groups
      @catalog_groups ||= (@catalog.constants - CATALOG_AGGREGATES).to_h do |group|
        [group, @catalog.const_get(group)]
      end
    end

    # Catalog groups this report cannot attribute to a Qt module; `CATALOG_MODULES` needs an entry
    # for each of them, and until it has one they are attributed to every module.
    def unattributed_groups = catalog_groups.keys - CATALOG_MODULES.keys

    # Catalog entries whose Zui name differs from the Qt type name. Most of the catalog renames its
    # type, which is why searching the component list for `combo_box` or `progress_bar` finds
    # nothing and the catalog looks far emptier than it is.
    def aliases
      catalog_groups.values.reduce({}, :merge)
                    .select { |_qt_type, component| @components.key?(component) }
                    .reject { |qt_type, component| snake_case(qt_type) == component.to_s }
                    .sort.to_h
    end

    def zui_native_components = @components.keys - covered.values.uniq

    UnsupportedReference = Struct.new(:source, :kind, :subject, :detail, keyword_init: true)

    # Adapters whose QML references something the pinned Qt SDK does not provide: a type no
    # imported module declares, a module version newer than the SDK's, or the adapter's own file
    # name, which resolves to the adapter itself instead of the Qt type it was meant to wrap.
    #
    # The host build and `rake test` both accept these, because neither resolves QML type names.
    def unsupported_references
      @unsupported_references ||= framework_sources.flat_map do |path|
        audit_source(path)
      end.sort_by { |reference| [reference.source, reference.kind.to_s, reference.subject] }
    end

    # Catalog entries that the module their group describes does not declare: a typo in the catalog,
    # a type Qt has moved, or a missing `CATALOG_MODULES` entry.
    def unmatched_catalog_types
      catalog_groups.values.reduce({}, :merge).keys - modules.flat_map(&:types).uniq
    end

    def to_markdown
      [preamble, totals, unsupported_section, alias_section, module_summary, module_details,
       native_section].join("\n")
    end

    def write!
      File.write(DOCUMENT_PATH, to_markdown)
      DOCUMENT_PATH
    end

    # Every type each Qt QML module declares, from its `qmldir` and its `.qmltypes` descriptions.
    def declared_types
      scan_sdk
      @declared_types
    end

    private

    # Framework QML in load order: the adapters, the control library, the theme and the entry
    # points. Every one of them is compiled into the application resource.
    def framework_sources
      Dir[File.join(@framework_root, "{Components,Controls,Theme}", "**", "*.qml")].sort +
        Dir[File.join(@framework_root, "*.qml")].sort
    end

    def audit_source(path)
      # QML an adapter assembles for `Qt.createQmlObject` carries its line breaks as escapes, so a
      # type is written `...6.10\nTreeModel {`. Turning the escapes into whitespace puts the
      # imports and type names of runtime-constructed QML on the same footing as static QML.
      text = read(path).gsub(/\\[nrt]/, " ")
      source = path.delete_prefix("#{@framework_root}/")
      own = File.basename(path, ".qml")
      imports, qualifiers, version_faults = source_imports(text, source)
      available = imports.flat_map { |name| module_closure(name).to_a }.uniq
                         .flat_map { |name| declared_types.fetch(name, []) }.to_set
      locals = framework_types - [own]
      declared_inline = text.scan(/component\s+([A-Z]\w*)\s*:/).flatten.to_set
      faults = version_faults
      text.scan(/(?:([A-Z][A-Za-z0-9_]*)\.)?\b([A-Z][A-Za-z0-9_]*)\s*\{/) do |qualifier, type|
        next if qualifier && !qualifiers.key?(qualifier)
        next if available.include?(type) || declared_inline.include?(type) || locals.include?(type)

        faults << if type == own
                    UnsupportedReference.new(
                      source:, kind: :self_reference, subject: type,
                      detail: "resolves to the adapter itself; no imported module declares #{type}"
                    )
                  else
                    UnsupportedReference.new(
                      source:, kind: :unknown_type, subject: type,
                      detail: "no module imported by this file declares #{type}"
                    )
                  end
      end
      faults.uniq { |fault| [fault.kind, fault.subject] }
    end

    # Imports of a QML file, including the ones inside string literals that an adapter assembles at
    # runtime, which is how `TreeView` asks for a module version the SDK does not have.
    def source_imports(text, source)
      imports = []
      qualifiers = {}
      faults = []
      text.scan(/(?:\A|\n|\\n|")\s*import\s+([A-Z][A-Za-z0-9_.]*)(?:\s+(\d+\.\d+))?(?:\s+as\s+([A-Z]\w*))?/) do |name, version, qualifier|
        imports << name
        qualifiers[qualifier] = name if qualifier
        available = module_versions[name]
        next unless version && available

        wanted = version.split(".").map(&:to_i)
        next unless (wanted <=> available) > 0

        faults << UnsupportedReference.new(
          source:, kind: :module_version, subject: "#{name} #{version}",
          detail: "the Qt #{qt_version} SDK provides #{name} up to #{available.join('.')}"
        )
      end
      [imports.uniq, qualifiers, faults]
    end

    def framework_types
      @framework_types ||= framework_sources.map { |path| File.basename(path, ".qml") }.to_set
    end

    def module_closure(name, seen = Set.new)
      return seen unless seen.add?(name)

      module_dependencies.fetch(name, []).each { |dependency| module_closure(dependency, seen) }
      seen
    end

    def imported?(name)
      @imported ||= QtModules.imported_by(@framework_root).keys.to_set
      @imported.include?(name)
    end

    def module_coverage(entry)
      name = entry.qml_module
      style = name.match?(STYLE_MODULE)
      types = style ? [] : declared_types.fetch(DEFAULT_STYLE.fetch(name, name), [])
      imported = imported?(name)
      ModuleCoverage.new(entry:, style:, types:, imported:,
                         coverage: imported ? coverage_for(name, types) : {})
    end

    # A type of an imported module is covered by the component its catalog group names, or by a
    # component that carries the type's own name in Ruby spelling.
    def coverage_for(name, types)
      catalog = catalog_groups.select do |group, _mapping|
        modules = CATALOG_MODULES[group]
        modules.nil? || modules.include?(name)
      end.values.reduce({}, :merge)
      types.each_with_object({}) do |type, coverage|
        component = catalog[type] || snake_case(type).to_sym
        coverage[type] = component if @components.key?(component)
      end
    end

    def preamble
      <<~MARKDOWN
        # Qt type coverage

        Generated by `rake qt:coverage` from the component registry, the Qt mobile catalog in
        `Zui::Mobile::ComponentCatalog`, `native/qt-modules.json` and the Qt #{qt_version} SDKs. Do
        not edit by hand.

        Every public Qt QML module is listed with the types it declares and the Zui component that
        renders each of them. A type counts as covered when the framework imports the module that
        declares it and either the mobile catalog maps the type to a registered component, or a
        registered component carries the type's own name in Ruby spelling. Covered therefore means
        the type has a Ruby builder method, a property and event schema and a QML adapter.

        Three things to keep in mind while reading the uncovered lists:

        * Not every Qt type is a component. Reading and value types (`AccelerometerReading`,
          `GeoCoordinate`), enumeration holders, attached property objects and abstract bases
          appear as uncovered because nothing should cover them.
        * A module no adapter imports has no covered types by definition, however familiar its type
          names look. `QtQuick.Templates`, the Qt Quick Controls styles and `Qt.labs.platform`
          declare many of the same names as the modules Zui does import.
        * Zui names are chosen for the Ruby API rather than copied from Qt — see the alias table.

        `docs/component-coverage.md` is the matching list from the other direction: every Zui
        component and whether it is implemented. `docs/qt-mobile-modules.md` explains how a module
        reaches a device.
      MARKDOWN
    end

    def totals
      declared = modules.reject(&:style?).flat_map(&:types).uniq
      <<~MARKDOWN
        ## Totals

        | | |
        | --- | ---: |
        | Qt QML modules | #{modules.size} |
        | Qt QML modules the framework imports | #{modules.count(&:imported?)} |
        | Qt types they declare | #{declared.size} |
        | Qt types covered by a Zui component | #{covered.size} |
        | Catalog entries naming a type no module declares | #{unmatched_catalog_types.size} |
        | Zui components | #{@components.size} |
        | Zui components that render a Qt type | #{covered.values.uniq.size} |
        | Zui components with no Qt counterpart | #{zui_native_components.size} |

        #{unmatched_section}
      MARKDOWN
    end

    def unmatched_section
      return "Every catalog entry names a type the Qt #{qt_version} SDK declares." if unmatched_catalog_types.empty?

      "Catalog entries no module declares: " \
        "#{unmatched_catalog_types.sort.map { |type| "`#{type}`" }.join(', ')}."
    end

    KIND_LABELS = {
      self_reference: "resolves to itself",
      unknown_type: "unknown type",
      module_version: "module version"
    }.freeze

    def unsupported_section
      if unsupported_references.empty?
        return <<~MARKDOWN
          ## Adapters the pinned Qt cannot satisfy

          None: every type and module version the framework QML names exists in the Qt
          #{qt_version} SDK.
        MARKDOWN
      end

      rows = unsupported_references.map do |reference|
        "| `#{reference.source}` | #{KIND_LABELS.fetch(reference.kind)} | `#{reference.subject}` | " \
          "#{reference.detail} |"
      end
      <<~MARKDOWN
        ## Adapters the pinned Qt cannot satisfy

        #{unsupported_references.size} reference(s) in the framework QML name a type or a module
        version the Qt #{qt_version} SDK does not provide. Neither the host build nor `rake test`
        resolves QML type names, so these fail only when the component is actually used — an
        adapter that names its own file name instantiates itself instead of the Qt type it was
        meant to wrap.

        | Source | Fault | Reference | Detail |
        | --- | --- | --- | --- |
        #{rows.join("\n")}
      MARKDOWN
    end

    def alias_section
      rows = aliases.map { |qt_type, component| "| `#{qt_type}` | `#{component}` |" }
      <<~MARKDOWN
        ## Qt name to Zui name

        #{aliases.size} Qt types are mapped to a Zui component with a different name.

        | Qt type | Zui component |
        | --- | --- |
        #{rows.join("\n")}
      MARKDOWN
    end

    def module_summary
      rows = modules.map do |mobile_module|
        entry = mobile_module.entry
        permissions = entry.android_permissions.map { |name| "`#{name.sub('android.permission.', '')}`" }
        "| `#{entry.qml_module}` | #{target_mark(entry, 'ios')} | #{target_mark(entry, 'android')} | " \
          "#{coverage_state(mobile_module)} | #{entry.sdk_module || 'base'} | " \
          "#{permissions.empty? ? '—' : permissions.join(' ')} |"
      end
      <<~MARKDOWN
        ## Modules

        A module reaches a target when the Qt SDK for that target ships it; `docs/qt-mobile-modules.md`
        records why the exceptions cannot. The SDK column names the add-on `zui mobile --fix`
        installs. The permissions are the ones `androiddeployqt` inserts into the Android manifest
        for the module itself; an application still declares its own runtime permissions and the
        matching iOS usage descriptions.

        | Qt QML module | iOS | Android | Types covered | SDK | Android permissions |
        | --- | :-: | :-: | --- | --- | --- |
        #{rows.join("\n")}
      MARKDOWN
    end

    def coverage_state(mobile_module)
      return "style implementation" if mobile_module.style?
      return "no declared types" if mobile_module.types.empty?
      return "not imported" unless mobile_module.imported?

      "#{mobile_module.covered_types.size} of #{mobile_module.types.size}"
    end

    def module_details
      sections = modules.reject { |mobile_module| mobile_module.style? || mobile_module.types.empty? }
                         .map { |mobile_module| module_section(mobile_module) }
      "\n## Types by module\n\n#{sections.join("\n")}"
    end

    def module_section(mobile_module)
      lines = ["### #{mobile_module.name}\n"]
      if mobile_module.covered_types.empty?
        state = mobile_module.imported? ? "No Zui component renders a type of this module yet" :
                                          "No adapter imports this module"
        lines << "#{state}. Declared types: " \
                 "#{mobile_module.types.map { |type| "`#{type}`" }.join(', ')}.\n"
      else
        lines << "| Qt type | Zui component |"
        lines << "| --- | --- |"
        mobile_module.covered_types.each do |type|
          lines << "| `#{type}` | `#{mobile_module.coverage.fetch(type)}` |"
        end
        lines << ""
        uncovered = mobile_module.uncovered_types
        lines << "Not covered: #{uncovered.map { |type| "`#{type}`" }.join(', ')}.\n" unless uncovered.empty?
      end
      lines.join("\n")
    end

    def native_section
      names = zui_native_components.map { |component| "`#{component}`" }.sort
      <<~MARKDOWN

        ## Zui components with no Qt counterpart

        #{names.size} components exist only in Zui: composed controls, charts drawn with Qt Quick
        Shapes, and framework concepts such as state and timing that have a Ruby API rather than a
        Qt type.

        #{names.join(', ')}.
      MARKDOWN
    end

    def target_mark(entry, target)
      entry.available_on?(target) ? "yes" : "no"
    end

    def snake_case(name)
      name.gsub(/([a-z\d])([A-Z])/, '\1_\2').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').downcase
    end

    # The `qmldir` of pure-QML modules and the `exports` of the `.qmltypes` descriptions that
    # `qmltyperegistrar` writes for C++ modules both contribute to `declared_types`.
    # The modules whose types an `import` also brings into scope: `depends`, plus the plain,
    # optional and default `import` lines a module's own `qmldir` declares.
    def module_dependencies
      scan_sdk
      @module_dependencies
    end

    # The highest version each module exports, as [major, minor].
    def module_versions
      scan_sdk
      @module_versions
    end

    def scan_sdk
      return if @declared_types

      @declared_types = {}
      @module_dependencies = {}
      @module_versions = {}
      Dir[File.join(@qt_root, "qml", "**", "qmldir")].each do |path|
        lines = read_lines(path)
        name = lines.filter_map { |line| line[/\A\s*module\s+(\S+)/, 1] }.first
        next unless name

        declarations = lines.filter_map { |line| line[/\A\s*([A-Z][A-Za-z0-9_]*)\s+(\d+\.\d+)\s+\S+\.qml\s*\z/, 1] }
        exported, versions = exported_types(File.dirname(path), name)
        @declared_types[name] = (declarations + exported).uniq.grep_v(INTERNAL_TYPE).sort
        @module_dependencies[name] = lines.filter_map do |line|
          line[/\A\s*(?:depends|(?:optional\s+|default\s+)?import)\s+([A-Za-z][A-Za-z0-9_.]*)/, 1]
        end.uniq
        versions += lines.filter_map { |line| line[/\A\s*[A-Z][A-Za-z0-9_]*\s+(\d+\.\d+)\s+\S+\.qml\s*\z/, 1] }
        highest = versions.map { |version| version.split(".").map(&:to_i) }.max
        @module_versions[name] = highest if highest
      end
    end

    def exported_types(directory, name)
      types = []
      versions = []
      Dir[File.join(directory, "*.qmltypes")].each do |path|
        read(path).scan(/exports:\s*\[([^\]]*)\]/m).flatten.each do |list|
          list.scan(/"([^"\/]+)\/([A-Z][A-Za-z0-9_]*)\s+([\d.]+)"/) do |qml_module, type, version|
            next unless qml_module == name

            types << type
            versions << version
          end
        end
      end
      [types, versions]
    end

    def read_lines(path)
      File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
    end

    def read(path)
      File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
    end
  end
end
