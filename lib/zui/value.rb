# frozen_string_literal: true

module Zui
  module Value
    MAX_DEPTH = 32
    MAX_ITEMS = 10_000
    def normalize(value, property: nil, depth: 0, seen: {}, count: [0])
      raise ArgumentError, "property value exceeds #{MAX_DEPTH} levels: #{property}" if depth > MAX_DEPTH
      count[0] += 1
      raise ArgumentError, "property value exceeds #{MAX_ITEMS} items: #{property}" if count[0] > MAX_ITEMS

      case value
      when Symbol then value.to_s
      when String, TrueClass, FalseClass, NilClass, Integer then value
      when Float
        raise ArgumentError, "property number must be finite: #{property}" unless value.finite?
        value
      when Array
        guard_cycle(value, property, seen) do
          value.map { |item| normalize(item, property:, depth: depth + 1, seen:, count:) }
        end
      when Hash
        guard_cycle(value, property, seen) do
          value.each_with_object({}) do |(key, item), result|
            result[key.to_s] = normalize(item, property:, depth: depth + 1, seen:, count:)
          end
        end
      else
        raise ArgumentError, "unsupported property value for #{property}: #{value.class}"
      end
    end

    def guard_cycle(value, property, seen)
      identity = value.object_id
      raise ArgumentError, "cyclic property value: #{property}" if seen[identity]
      seen[identity] = true
      yield
    ensure
      seen.delete(identity)
    end

    module_function :normalize, :guard_cycle
  end
end
