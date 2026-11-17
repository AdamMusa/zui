# frozen_string_literal: true

require "fileutils"

module Zui
  module MacOSQmlPayload
    module_function

    def deduplicate!(client_root)
      contents = File.join(client_root, "zui-host.app", "Contents")
      qml_root = File.join(contents, "Resources", "qml")
      duplicate_root = File.join(contents, "PlugIns", "quick")
      return 0 unless File.directory?(duplicate_root)
      unless File.directory?(qml_root)
        raise ArgumentError, "deployed macOS QML tree is missing: #{qml_root}"
      end

      missing = required_plugins(qml_root).reject do |directory, plugin_name|
        File.file?(File.join(directory, "lib#{plugin_name}.dylib")) ||
          File.file?(File.join(directory, "#{plugin_name}.dylib"))
      end
      unless missing.empty?
        directory, plugin_name = missing.first
        relative = directory.delete_prefix("#{qml_root}#{File::SEPARATOR}")
        raise ArgumentError, "macOS QML plugin #{plugin_name} is missing from #{relative}"
      end

      saved = Dir[File.join(duplicate_root, "**", "*")].sum do |path|
        File.file?(path) && !File.symlink?(path) ? File.size(path) : 0
      end
      FileUtils.remove_entry(duplicate_root)
      saved
    end

    def required_plugins(qml_root)
      Dir[File.join(qml_root, "**", "qmldir")].sort.flat_map do |qmldir|
        File.foreach(qmldir).filter_map do |line|
          name = line[/\A\s*(?:optional\s+)?plugin\s+([A-Za-z0-9._+-]+)/, 1]
          [File.dirname(qmldir), name] if name
        end
      end.uniq
    end
    private_class_method :required_plugins
  end
end
