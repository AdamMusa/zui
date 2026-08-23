# frozen_string_literal: true

module Zui
  class Animation
    EASINGS = %w[linear in_quad out_quad in_out_quad in_cubic out_cubic in_out_cubic
                 in_back out_back in_out_back in_elastic out_elastic in_out_elastic
                 in_bounce out_bounce in_out_bounce].freeze

    attr_reader :duration, :easing, :delay

    def initialize(duration: 200, easing: :in_out_quad, delay: 0)
      @duration = Integer(duration)
      @delay = Integer(delay)
      @easing = easing.to_s
      raise ArgumentError, "animation duration must be between 0 and 60 seconds" unless (0..60_000).cover?(@duration)
      raise ArgumentError, "animation delay must be between 0 and 60 seconds" unless (0..60_000).cover?(@delay)
      raise ArgumentError, "unsupported easing: #{@easing}" unless EASINGS.include?(@easing)
    end

    def to_h
      { "duration" => duration, "easing" => easing, "delay" => delay }
    end
  end
end
