# frozen_string_literal: true

module Zui
  PROTOCOL_VERSION = 1
  MAX_MESSAGE_BYTES = 1_048_576
  class AsciiPattern
    def initialize(min:, max:, first: nil, rest:)
      @min = min
      @max = max
      @first = first
      @rest = rest
    end

    def match?(value)
      text = value.to_s
      return false if text.length < @min || text.length > @max
      return false if @first && !@first.include?(text[0])
      text.each_char.all? { |character| @rest.include?(character) }
    end
  end

  LOWER = ("a".."z").to_a.join.freeze
  UPPER = ("A".."Z").to_a.join.freeze
  DIGITS = ("0".."9").to_a.join.freeze
  VALID_ID = AsciiPattern.new(min: 1, max: 128, rest: LOWER + UPPER + DIGITS + "_.:-")
  VALID_EVENT = AsciiPattern.new(min: 1, max: 64, first: LOWER, rest: LOWER + DIGITS + "_")

  class ProtocolError < StandardError; end
end
