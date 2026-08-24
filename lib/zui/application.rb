# frozen_string_literal: true

require "json" unless Object.const_defined?(:JSON)
require "thread" unless Object.const_defined?(:Mutex)

module Zui
  class Application
    ANIMATION_DEFAULTS = { "opacity" => 1.0, "scale" => 1.0, "rotation" => 0.0, "z" => 0.0 }.freeze
    attr_reader :state, :surfaces, :surface_options, :components

    def initialize(components: DEFAULT_COMPONENTS, ui: nil, &definition)
      @surfaces = {}
      @surface_options = {}
      @nodes = {}
      @bindings = []
      @structures = []
      @handlers = {}
      @sequence = 0
      @output = nil
      @error = $stderr
      @running = false
      @patch_batch = nil
      @write_lock = Mutex.new
      @state_change_lock = Mutex.new
      @components = components.dup
      @builder = Builder.new(self)
      builder_extensions = Array(ui).compact
      unless builder_extensions.all? { |extension| extension.is_a?(Module) }
        raise ArgumentError, "ui extensions must be modules"
      end
      @builder.extend(*builder_extensions) unless builder_extensions.empty?
      @state = StateStore.new(method(:state_changed))
      @scheduler = Scheduler.new(evaluator: method(:evaluate), on_error: method(:report_internal_error))
      @builder.instance_eval(&definition) if definition
      raise ArgumentError, "plugin defines no surfaces" if @surfaces.empty?
    end

    def define_state(name, initial) = @state.define(name, initial)

    def build_node(type, explicit_id: nil, props: {})
      definition = @components.fetch(type)
      @sequence += 1
      id = explicit_id ? explicit_id.to_s : "#{type}.#{@sequence}"
      validate_id!(id)
      raise ArgumentError, "duplicate control id: #{id}" if @nodes.key?(id)

      normalized_props = normalize_props(props)
      unknown = normalized_props.keys - definition.properties.map(&:to_s)
      raise ArgumentError, "unsupported properties for #{type}: #{unknown.join(', ')}" unless unknown.empty?
      Node.new(type:, id:, props: normalized_props).tap { |node| @nodes[id] = node }
    end

    def add_surface(name, node, options: {})
      key = name.to_s
      validate_id!(key)
      raise ArgumentError, "duplicate surface: #{key}" if @surfaces.key?(key)
      @surfaces[key] = node
      @surface_options[key] = options.transform_keys(&:to_s).transform_values { |value| normalize_value(value) }
    end

    def register_binding(node, property, reader, animation: nil)
      property = property.to_s
      unless @components.fetch(node.type).properties.map(&:to_s).include?(property)
        raise ArgumentError, "unsupported bound property for #{node.type}: #{property}"
      end
      value = normalize_value(evaluate(reader), property)
      node.props[property] = value
      @bindings << Binding.new(node:, property:, reader:, last_value: value, animation:)
    end

    def register_structure(node, renderer)
      @structures << StructuralBinding.new(node:, renderer:, last_children: node.children.map(&:to_h))
    end

    def register_handler(control_id, event, handler)
      raise ArgumentError, "handler requires a block" unless handler
      node = @nodes.fetch(control_id.to_s) { raise ArgumentError, "unknown event control: #{control_id}" }
      event_name = event.to_s
      declared = @components.fetch(node.type).events.map(&:to_s)
      unless declared.include?(event_name) || %w[mount unmount].include?(event_name)
        raise ArgumentError, "#{node.type} does not declare event: #{event_name}"
      end
      node.subscribe(event_name)
      key = [control_id.to_s, event_name]
      raise ArgumentError, "duplicate handler for #{key.join('/')}" if @handlers.key?(key)
      @handlers[key] = handler
    end

    def emit_effect(name, payload = {})
      emit("v" => PROTOCOL_VERSION, "type" => "effect", "name" => name.to_s, "payload" => payload)
    end

    def animate(node, properties, animation)
      emit_animation(node, animation_tracks(node, properties, animation))
    end

    def animation_tracks(node, properties, animation)
      definition = @components.fetch(node.type)
      properties.map do |property, value|
        property_name = property.to_s
        unless definition.properties.map(&:to_s).include?(property_name)
          raise ArgumentError, "unsupported animated property for #{node.type}: #{property_name}"
        end
        normalized = normalize_value(value, property_name)
        track = {
          "property" => property_name,
          "from" => node.props.fetch(property_name, ANIMATION_DEFAULTS[property_name]),
          "to" => normalized
        }.merge(animation.to_h)
        node.props[property_name] = normalized
        track
      end
    end

    def emit_animation(node, tracks)
      raise ArgumentError, "animation requires at least one property" if tracks.empty?
      emit("v" => PROTOCOL_VERSION, "type" => "patch", "op" => "animate", "id" => node.id, "tracks" => tracks)
      node
    end

    def tree = @surfaces.transform_values(&:to_h)
    def normalize_value(value, property = nil) = Value.normalize(value, property:)

    def start(output: $stdout, error: $stderr)
      @output = output
      @error = error
      @output.sync = true if @output.respond_to?(:sync=)
      @error.sync = true if @error.respond_to?(:sync=)
      @running = true
      pid = Object.const_defined?(:Process) && Process.respond_to?(:pid) ? Process.pid : 0
      emit("v" => PROTOCOL_VERSION, "type" => "ready", "pid" => pid, "surfaces" => @surfaces.keys)
      emit("v" => PROTOCOL_VERSION, "type" => "render", "components" => @components.protocol_schema,
           "surfaces" => tree, "surface_options" => @surface_options)
      @scheduler.start
      self
    end

    def run(input: $stdin, output: $stdout, error: $stderr)
      start(output:, error:)
      input.each_line do |line|
        receive(line)
      rescue StandardError => exception
        report_internal_error(exception)
      end
    ensure
      stop
    end

    def stop
      @running = false
      @scheduler.stop
      self
    end

    def schedule(kind, interval: 0, immediate: false, &block)
      @scheduler.schedule(kind, interval:, immediate:, &block)
    end

    def receive(raw_line)
      raise ProtocolError, "message exceeds #{MAX_MESSAGE_BYTES} bytes" if raw_line.bytesize > MAX_MESSAGE_BYTES
      message = JSON.parse(raw_line)
      if message.is_a?(Hash) && message["v"] == PROTOCOL_VERSION && message["type"] == "tick"
        @scheduler.tick
        return
      end
      validate_message!(message)
      dispatch_event(message)
    rescue JSON::ParserError => exception
      emit_protocol_error("invalid_json", exception.message)
    rescue ProtocolError => exception
      emit_protocol_error("invalid_message", exception.message)
    end

    private

    def state_changed(_name, _previous, _value)
      @state_change_lock.synchronize do
        @patch_batch = []
        begin
          @structures.dup.each do |structure|
            reconcile_structure(structure) if @structures.include?(structure)
          end
          @bindings.dup.each { |binding| update_binding(binding) }
        ensure
          patches = @patch_batch
          @patch_batch = nil
        end
        flush_patch_batch(patches)
      end
    end

    def flush_patch_batch(patches)
      return if patches.empty?
      return emit(patches.first) if patches.length == 1

      batch = {
        "v" => PROTOCOL_VERSION, "type" => "patch", "op" => "batch",
        "patches" => patches.map { |patch| patch.reject { |key, _| %w[v type].include?(key) } }
      }
      return emit(batch) if JSON.generate(batch).bytesize <= MAX_MESSAGE_BYTES

      patches.each { |patch| emit(patch) }
    end

    def update_binding(binding)
      value = normalize_value(evaluate(binding.reader), binding.property)
      return if value == binding.last_value
      binding.last_value = value
      binding.node.props[binding.property] = value
      patch = {
        "v" => PROTOCOL_VERSION, "type" => "patch", "op" => "set",
        "id" => binding.node.id, "property" => binding.property, "value" => value
      }
      patch["animation"] = binding.animation.to_h if binding.animation
      emit(patch)
    end

    def reconcile_structure(structure)
      previous_children = structure.last_children
      structure.node.children.dup.each { |child| unregister_subtree(child) }
      structure.node.children.clear
      @builder.rebuild(structure.node, &structure.renderer)
      children = structure.node.children.map(&:to_h)
      return if children == structure.last_children
      if patchable_trees?(previous_children, children)
        emit_property_patches(previous_children, children)
        structure.last_children = children
        return
      end
      structure.last_children = children
      emit("v" => PROTOCOL_VERSION, "type" => "patch", "op" => "replace_children",
           "id" => structure.node.id, "children" => children)
    end

    def patchable_trees?(previous, current)
      return false unless previous.length == current.length
      previous.zip(current).all? do |before, after|
        before["id"] == after["id"] && before["type"] == after["type"] &&
          before.fetch("events", []) == after.fetch("events", []) &&
          before.fetch("props", {}).keys.sort == after.fetch("props", {}).keys.sort &&
          patchable_trees?(before.fetch("children", []), after.fetch("children", []))
      end
    end

    def emit_property_patches(previous, current)
      previous.zip(current).each do |before, after|
        before.fetch("props", {}).each do |property, old_value|
          value = after.fetch("props", {}).fetch(property)
          next if value == old_value
          next if echoed_input_patch?(after.fetch("id"), property, value)
          emit("v" => PROTOCOL_VERSION, "type" => "patch", "op" => "set",
               "id" => after.fetch("id"), "property" => property, "value" => value)
        end
        emit_property_patches(before.fetch("children", []), after.fetch("children", []))
      end
    end

    def echoed_input_patch?(control_id, property, value)
      @active_event && @active_event["event"] == "input" && @active_event["id"] == control_id &&
        %w[text value].include?(property) && @active_event.dig("payload", "value") == value
    end

    def unregister_subtree(node)
      node.children.each { |child| unregister_subtree(child) }
      @nodes.delete(node.id)
      @bindings.delete_if { |binding| binding.node.equal?(node) }
      @structures.delete_if { |structure| structure.node.equal?(node) }
      @handlers.delete_if { |(control_id, _event), _handler| control_id == node.id }
    end

    def dispatch_event(message)
      key = [message.fetch("id"), message.fetch("event")]
      handler = @handlers[key]
      raise ProtocolError, "unknown event target: #{key.join('/')}" unless handler
      begin
        @active_event = message
        @builder.instance_exec(message["payload"] || {}, &handler)
      ensure
        @active_event = nil
      end
      acknowledgement = {
        "v" => PROTOCOL_VERSION, "type" => "ack", "seq" => message["seq"],
        "id" => message.fetch("id"), "event" => message.fetch("event")
      }
      acknowledgement["rss_kib"] = process_rss_kib if message.dig("payload", "diagnostics") == true
      emit(acknowledgement)
    rescue StandardError => exception
      emit("v" => PROTOCOL_VERSION, "type" => "handler_error", "seq" => message["seq"],
           "id" => message["id"], "message" => exception.message.to_s[0, 500])
      @error.puts("zui handler error: #{exception.class}: #{exception.message}")
    end

    def validate_message!(message)
      raise ProtocolError, "message must be an object" unless message.is_a?(Hash)
      raise ProtocolError, "unsupported protocol version" unless message["v"] == PROTOCOL_VERSION
      raise ProtocolError, "unsupported message type" unless message["type"] == "event"
      raise ProtocolError, "invalid surface" unless VALID_ID.match?(message["surface"].to_s)
      raise ProtocolError, "unknown surface" unless @surfaces.key?(message["surface"])
      raise ProtocolError, "invalid control id" unless VALID_ID.match?(message["id"].to_s)
      unless surface_contains?(@surfaces.fetch(message["surface"]), message["id"])
        raise ProtocolError, "control does not belong to surface"
      end
      raise ProtocolError, "invalid event" unless VALID_EVENT.match?(message["event"].to_s)
      unless message["payload"].nil? || message["payload"].is_a?(Hash)
        raise ProtocolError, "payload must be an object"
      end
      raise ProtocolError, "seq must be an integer" unless message["seq"].nil? || message["seq"].is_a?(Integer)
    end

    def surface_contains?(node, control_id)
      node.id == control_id || node.children.any? { |child| surface_contains?(child, control_id) }
    end

    def evaluate(callable) = @builder.instance_exec(&callable)

    def normalize_props(props)
      props.each_with_object({}) { |(key, value), result| result[key.to_s] = normalize_value(value, key) }
    end

    def validate_id!(id)
      raise ArgumentError, "invalid id: #{id.inspect}" unless VALID_ID.match?(id)
    end

    def emit(message)
      return unless @running && @output
      if @patch_batch && message["type"] == "patch" && message["op"] == "set"
        @patch_batch << message
        return
      end
      encoded = JSON.generate(message)
      raise ProtocolError, "outgoing message exceeds #{MAX_MESSAGE_BYTES} bytes" if encoded.bytesize > MAX_MESSAGE_BYTES
      @write_lock.synchronize { @output.puts(encoded) }
    end

    def emit_protocol_error(code, message)
      emit("v" => PROTOCOL_VERSION, "type" => "protocol_error", "code" => code,
           "message" => message.to_s[0, 500])
    end

    def report_internal_error(exception)
      @error.puts("zui runtime error: #{exception.class}: #{exception.message}")
      emit("v" => PROTOCOL_VERSION, "type" => "runtime_error", "message" => exception.message.to_s[0, 500])
    end

    def process_rss_kib
      line = File.read("/proc/self/status").each_line.find { |entry| entry.start_with?("VmRSS:") }
      line ? line.split[1].to_i : 0
    rescue SystemCallError
      0
    end
  end
end
