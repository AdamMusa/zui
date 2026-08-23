# frozen_string_literal: true

module Zui
  class Node
    attr_reader :type, :id, :props, :children, :events

    def initialize(type:, id:, props: {})
      @type = type.to_s
      @id = id.to_s
      @props = props.transform_keys(&:to_s)
      @children = []
      @events = []
    end

    def to_h
      result = { "type" => type, "id" => id }
      result["props"] = props unless props.empty?
      result["children"] = children.map(&:to_h) unless children.empty?
      result["events"] = events unless events.empty?
      result
    end

    def subscribe(event)
      @events << event.to_s unless @events.include?(event.to_s)
    end
  end

  Binding = Struct.new(:node, :property, :reader, :last_value, :animation, keyword_init: true)
  StructuralBinding = Struct.new(:node, :renderer, :last_children, keyword_init: true)
end
