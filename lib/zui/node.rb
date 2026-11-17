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

  class Binding
    # `reads` is the set of state keys the reader touched when it last ran, so
    # a write only re-runs the readers that depend on it. Empty means the
    # reader read no state at all, and such a reader is always re-run: its
    # value may come from somewhere this cannot see.
    attr_accessor :last_value, :reads
    attr_reader :node, :property, :reader, :animation

    def initialize(node:, property:, reader:, last_value:, animation:, reads: [])
      @node = node
      @property = property
      @reader = reader
      @last_value = last_value
      @animation = animation
      @reads = reads
    end

    def reads_any?(keys)
      return true if @reads.nil? || @reads.empty?

      keys.any? { |key| @reads.include?(key) }
    end
  end

  class StructuralBinding
    attr_accessor :last_children, :reads
    attr_reader :node, :renderer

    def initialize(node:, renderer:, last_children:, reads: [])
      @node = node
      @renderer = renderer
      @last_children = last_children
      @reads = reads
    end

    def reads_any?(keys)
      return true if @reads.nil? || @reads.empty?

      keys.any? { |key| @reads.include?(key) }
    end
  end
end
