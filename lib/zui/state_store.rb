# frozen_string_literal: true

module Zui
  class StateStore
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
      @lock.synchronize { @values.fetch(name.to_sym) }
    end

    def []=(name, value)
      write(name.to_sym, value)
    end

    def update(name)
      raise ArgumentError, "update requires a block" unless block_given?
      key = name.to_sym
      change, value = @lock.synchronize do
        raise NoMethodError, "unknown state: #{key}" unless @values.key?(key)
        next_value = yield(@values[key])
        [store_locked(key, next_value), next_value]
      end
      @on_change.call(*change) if change
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
        return value if found
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
      changes.each { |change| @on_change.call(*change) }
    end

    private

    def write(key, value)
      change = @lock.synchronize do
        raise NoMethodError, "unknown state: #{key}" unless @values.key?(key)
        store_locked(key, value)
      end
      @on_change.call(*change) if change
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
