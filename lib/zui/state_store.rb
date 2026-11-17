# frozen_string_literal: true

module Zui
  class StateStore
    # Reactive dependency tracking.
    #
    # While a bound reader or a `dynamic` renderer runs, every state key it
    # actually reads is recorded in the innermost open frame. A later write then
    # only has to re-run the readers that read that key, instead of all of them.
    # Frames nest because rebuilding a renderer registers the bindings inside
    # it: a nested binding records its own reads and does not attribute them to
    # the renderer around it, whose shape does not depend on them.
    def self.capture
      stack = read_stack
      frame = {}
      stack.push(frame)
      begin
        [yield, frame.keys]
      ensure
        stack.pop
      end
    end

    def self.record(key)
      stack = read_stack
      return if stack.empty?

      stack[-1][key] = true
    end

    # Frames are per-thread where the runtime has usable thread locals, so a
    # scheduler callback cannot contaminate a frame opened on another thread.
    # The lite mruby runtime may not provide them, and there it is single
    # threaded anyway, so one shared stack is correct there.
    def self.read_stack
      @shared_stack ||= []
      return @shared_stack unless defined?(Thread)

      current = Thread.current
      return @shared_stack unless current.respond_to?(:[]) && current.respond_to?(:[]=)

      current[:zui_state_reads] ||= []
    rescue StandardError
      @shared_stack
    end

    def initialize(on_change)
      @values = {}
      @on_change = on_change
      @lock = Mutex.new
      @transaction_depth = 0
      @pending = {}
    end

    def define(name, initial)
      key = name.to_sym
      @lock.synchronize do
        raise ArgumentError, "state already defined: #{key}" if @values.key?(key)
        @values[key] = initial
      end
    end

    def [](name)
      key = name.to_sym
      self.class.record(key)
      @lock.synchronize { @values.fetch(key) }
    end

    def []=(name, value)
      write(name.to_sym, value)
    end

    def update(name)
      raise ArgumentError, "update requires a block" unless block_given?
      key = name.to_sym
      self.class.record(key)
      change, value = @lock.synchronize do
        raise NoMethodError, "unknown state: #{key}" unless @values.key?(key)
        next_value = yield(@values[key])
        [store_locked(key, next_value), next_value]
      end
      @on_change.call([change]) if change
      value
    end

    def method_missing(name, *arguments)
      raw = name.to_s
      if raw.end_with?("=")
        raise ArgumentError, "expected one value" unless arguments.length == 1

        return write(raw.delete_suffix("=").to_sym, arguments.first)
      end
      if arguments.empty?
        found, value = @lock.synchronize { [@values.key?(name), @values[name]] }
        if found
          self.class.record(name)
          return value
        end
      end

      super
    end

    def respond_to_missing?(name, include_private = false)
      key = name.to_s.delete_suffix("=").to_sym
      @lock.synchronize { @values.key?(key) } || super
    end

    def transaction
      raise ArgumentError, "transaction requires a block" unless block_given?
      @lock.synchronize { @transaction_depth += 1 }
      yield self
    ensure
      changes = @lock.synchronize do
        @transaction_depth -= 1
        next [] unless @transaction_depth.zero?
        flushed = @pending.values
        @pending.clear
        flushed
      end
      # One call for the whole transaction, not one per key: the readers that
      # depend on several of these keys must see them all at once, and their
      # patches have to reach the client as a single atomic batch.
      @on_change.call(changes) unless changes.empty?
    end

    private

    def write(key, value)
      change = @lock.synchronize do
        raise NoMethodError, "unknown state: #{key}" unless @values.key?(key)
        store_locked(key, value)
      end
      @on_change.call([change]) if change
      value
    end

    def store_locked(key, value)
      return nil if @values[key] == value
      previous = @values[key]
      @values[key] = value
      if @transaction_depth.positive?
        @pending[key] ||= [key, previous, value]
        @pending[key][2] = value
        nil
      else
        [key, previous, value]
      end
    end
  end
end
