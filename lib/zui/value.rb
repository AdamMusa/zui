# frozen_string_literal: true

module Zui
  module Value
    # The native client refuses a whole render, a whole replace_children or a
    # whole patch batch when one property value is past these (Service.qml,
    # boundedValue), and it tells Ruby nothing. A value that gets this far in
    # Ruby therefore does not fail where it was written: the interface just
    # stays blank or stale. They are enforced here so it fails there instead,
    # with the property named.
    MAX_DEPTH = 8
    MAX_COLLECTION = 256
    MAX_STRING = 16_384
    MAX_KEY = 128
    MAX_ITEMS = 10_000
    def normalize(value, property: nil, depth: 0, seen: {}, count: [0])
      raise ArgumentError, "property value exceeds #{MAX_DEPTH} levels: #{property}" if depth > MAX_DEPTH
      count[0] += 1
      raise ArgumentError, "property value exceeds #{MAX_ITEMS} items: #{property}" if count[0] > MAX_ITEMS

      case value
      when Symbol then bounded_string(value.to_s, property)
      when String then bounded_string(value, property)
      when TrueClass, FalseClass, NilClass, Integer then value
      when Float
        raise ArgumentError, "property number must be finite: #{property}" unless value.finite?
        value
      when Array
        check_collection(value.length, property)
        guard_cycle(value, property, seen) do
          value.map { |item| normalize(item, property:, depth: depth + 1, seen:, count:) }
        end
      when Hash
        check_collection(value.length, property)
        guard_cycle(value, property, seen) do
          value.each_with_object({}) do |(key, item), result|
            key = bounded_string(key.to_s, property, limit: MAX_KEY, what: "key")
            result[key] = normalize(item, property:, depth: depth + 1, seen:, count:)
          end
        end
      else
        raise ArgumentError, "unsupported property value for #{property}: #{value.class}"
      end
    end

    def check_collection(length, property)
      return if length <= MAX_COLLECTION

      raise ArgumentError, "property value holds #{length} items, the client takes #{MAX_COLLECTION}: #{property}"
    end

    # The client measures strings in UTF-16 code units, which is not what
    # String#length counts. A string of at most `limit` bytes cannot exceed it
    # in either unit, so only the longer ones are measured.
    def bounded_string(string, property, limit: MAX_STRING, what: "string")
      return string if string.bytesize <= limit

      units = string.length + string.each_char.count { |character| character.ord > 0xFFFF }
      return string if units <= limit

      raise ArgumentError, "property #{what} is #{units} characters, the client takes #{limit}: #{property}"
    end

    def guard_cycle(value, property, seen)
      identity = value.object_id
      raise ArgumentError, "cyclic property value: #{property}" if seen[identity]
      seen[identity] = true
      yield
    ensure
      seen.delete(identity)
    end

    module_function :normalize, :guard_cycle, :check_collection, :bounded_string
  end
end
