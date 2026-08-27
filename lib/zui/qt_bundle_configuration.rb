# frozen_string_literal: true

require "json"

module Zui
  class QtBundleConfiguration
    CONFIG_FILE = ".zui-bundle.json"
    DEFAULT_STYLE = "Fusion"
    FEATURES = %w[
      gif ico jpeg network-reachability svg svg-icons tls webp
    ].freeze
    QT_NAME = /\A[A-Za-z][A-Za-z0-9_.+-]*\z/
    PLUGIN_NAME = /\A[A-Za-z0-9][A-Za-z0-9_.+-]*\/[A-Za-z0-9][A-Za-z0-9_.+-]*\z/
    RUBY_FEATURE = /\A[A-Za-z0-9][A-Za-z0-9_.\/-]*\z/

    attr_reader :components, :style, :features, :qml_modules, :plugins, :ruby_stdlib

    def self.load(project)
      new(File.join(File.expand_path(project), CONFIG_FILE))
    end

    def initialize(path)
      document = read_document(path)
      @components = string_array(document.fetch("components", []), "components")
      qt = document.fetch("qt", {})
      raise ArgumentError, "#{CONFIG_FILE} qt must be a JSON object" unless qt.is_a?(Hash)

      @style_explicit = qt.key?("style")
      @style = qt.fetch("style", DEFAULT_STYLE)
      unless @style.is_a?(String) && @style.match?(QT_NAME)
        raise ArgumentError, "#{CONFIG_FILE} qt.style must be a Qt Quick Controls style name"
      end
      @features = string_array(qt.fetch("features", []), "qt.features", pattern: QT_NAME)
      unknown_features = @features - FEATURES
      unless unknown_features.empty?
        raise ArgumentError, "#{CONFIG_FILE} has unknown Qt features: #{unknown_features.join(', ')}"
      end
      @qml_modules = string_array(qt.fetch("qml_modules", []), "qt.qml_modules", pattern: QT_NAME)
      @plugins = string_array(qt.fetch("plugins", []), "qt.plugins", pattern: PLUGIN_NAME)
      ruby = document.fetch("ruby", {})
      raise ArgumentError, "#{CONFIG_FILE} ruby must be a JSON object" unless ruby.is_a?(Hash)

      @ruby_stdlib = string_array(ruby.fetch("stdlib", []), "ruby.stdlib", pattern: RUBY_FEATURE)
      unsafe = @ruby_stdlib.select do |feature|
        feature.start_with?("/") || feature.split("/").any? { |part| %w[. ..].include?(part) }
      end
      unless unsafe.empty?
        raise ArgumentError, "#{CONFIG_FILE} ruby.stdlib contains unsafe features: #{unsafe.join(', ')}"
      end
    end

    def to_h
      {
        "style" => style,
        "features" => features,
        "qml_modules" => qml_modules,
        "plugins" => plugins
      }
    end

    def style_explicit? = @style_explicit

    private

    def read_document(path)
      return {} unless File.file?(path)

      document = JSON.parse(File.read(path))
      raise ArgumentError, "#{CONFIG_FILE} must contain a JSON object" unless document.is_a?(Hash)

      document
    rescue JSON::ParserError => error
      raise ArgumentError, "invalid #{CONFIG_FILE}: #{error.message}"
    end

    def string_array(value, key, pattern: nil)
      valid = value.is_a?(Array) && value.all? do |entry|
        entry.is_a?(String) && !entry.empty? && (!pattern || entry.match?(pattern))
      end
      raise ArgumentError, "#{CONFIG_FILE} #{key} must be an array of valid names" unless valid

      value.uniq.sort.freeze
    end
  end
end
