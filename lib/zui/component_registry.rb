# frozen_string_literal: true

module Zui
  class Component
    attr_reader :name, :qml, :properties, :events, :property_map, :event_map, :container, :auto_bind, :built_in

    def initialize(name:, qml:, properties:, events:, property_map:, event_map:, container:, auto_bind:, built_in:)
      @name = name
      @qml = qml
      @properties = properties
      @events = events
      @property_map = property_map
      @event_map = event_map
      @container = container
      @auto_bind = auto_bind
      @built_in = built_in
    end

    def to_h
      {
        "qml" => qml,
        "properties" => properties.map(&:to_s),
        "events" => events.map(&:to_s),
        "property_map" => property_map.transform_keys(&:to_s).transform_values(&:to_s),
        "event_map" => event_map.transform_keys(&:to_s).transform_values(&:to_s),
        "container" => container,
        "auto_bind" => auto_bind,
        "built_in" => built_in
      }
    end
  end

  class ComponentRegistry
    QML_FILE = Object.new
    def QML_FILE.match?(value)
      text = value.to_s
      stem = text.end_with?(".qml") ? text[0...-4] : ""
      !stem.empty? && Zui::UPPER.include?(stem[0]) && stem.each_char.all? do |character|
        (Zui::LOWER + Zui::UPPER + Zui::DIGITS).include?(character)
      end
    end
    NAME = AsciiPattern.new(min: 1, max: 64, first: LOWER, rest: LOWER + DIGITS + "_")
    ITEM_PROPERTIES = %i[
      visible enabled opacity scale rotation z width height
      fill_width fill_height preferred_width preferred_height
      minimum_width minimum_height maximum_width maximum_height layout_alignment
    ].freeze

    def initialize
      @components = {}
    end

    def register(name, qml:, properties: [], events: [], property_map: {}, event_map: {}, container: false,
                 auto_bind: true, built_in: false)
      key = name.to_sym
      raise ArgumentError, "component already registered: #{key}" if @components.key?(key)
      raise ArgumentError, "invalid component name: #{name.inspect}" unless NAME.match?(key.to_s)
      raise ArgumentError, "invalid component adapter: #{qml.inspect}" unless QML_FILE.match?(qml.to_s)
      property_names = (properties.map(&:to_sym) + property_map.keys.map(&:to_sym) + ITEM_PROPERTIES).uniq
      event_names = (events.map(&:to_sym) + event_map.keys.map(&:to_sym)).uniq
      normalized_property_map = properties.to_h { |property| [property.to_sym, property.to_sym] }
      normalized_property_map.merge!(property_map.to_h { |key, value| [key.to_sym, value.to_sym] })
      normalized_event_map = events.to_h { |event| [event.to_sym, event.to_sym] }
      normalized_event_map.merge!(event_map.to_h { |key, value| [key.to_sym, value.to_sym] })
      invalid_property = property_names.find { |property| !NAME.match?(property.to_s) }
      invalid_event = event_names.find { |event| !NAME.match?(event.to_s) }
      raise ArgumentError, "invalid property name: #{invalid_property.inspect}" if invalid_property
      raise ArgumentError, "invalid event name: #{invalid_event.inspect}" if invalid_event
      invalid_target = (normalized_property_map.values + normalized_event_map.values).find { |target| !NAME.match?(target.to_s) }
      raise ArgumentError, "invalid QML member name: #{invalid_target.inspect}" if invalid_target

      @components[key] = Component.new(
        name: key,
        qml: qml.to_s,
        properties: property_names.uniq.freeze,
        events: event_names.uniq.freeze,
        property_map: normalized_property_map.freeze,
        event_map: normalized_event_map.freeze,
        container: !!container,
        auto_bind: !!auto_bind,
        built_in: !!built_in
      )
    end

    def fetch(name)
      @components.fetch(name.to_sym) { raise ArgumentError, "unknown component: #{name}" }
    end

    def key?(name)
      @components.key?(name.to_sym)
    end

    def protocol_schema
      @components.transform_keys(&:to_s).transform_values(&:to_h)
    end

    # Every application duplicates the default registry before it builds its
    # first node, and re-registering all three hundred components cost it
    # thirty-five milliseconds of validation it had already paid for once at
    # load time. A Component exposes no writer and holds frozen collections, so
    # the copy can share them; only the index has to be its own, which is what
    # lets the copy register components the original does not have.
    #
    # Re-registering also widened the result: the second pass fed the already
    # expanded property list back through normalization and added an identity
    # mapping for every common item property, inflating the component schema
    # the client is sent on every launch.
    def dup
      copy = self.class.new
      # Reached through send because mruby, which the lite runtime uses, does
      # not let one instance call another's protected method.
      copy.send(:adopt_components, @components)
      copy
    end

    private

    # Only ComponentRegistry#dup has any business handing a registry its index.
    def adopt_components(components)
      @components = components.dup
    end
  end
end
