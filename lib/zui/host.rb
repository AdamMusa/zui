# frozen_string_literal: true

module Zui
  class Host
    attr_reader :client, :platform

    def initialize(platform: Platform.current, environment: ENV, client: nil)
      @platform = platform.assert_supported!
      @environment = environment
      @client = client || Client.new(platform:, environment:)
    end

    def executable
      override = @environment["ZUI_HOST"]
      return checked_executable(override) if override && !override.empty?
      return client.executable if client.configured?

      raise ArgumentError, "Zui is not configured for #{platform.id}; run `zui configure`"
    end

    def available?
      override = @environment["ZUI_HOST"]
      return File.executable?(File.expand_path(override)) if override && !override.empty?

      client.configured?
    end

    def configure! = client.configure!

    def environment(base = ENV.to_h)
      override = @environment["ZUI_HOST"]
      return base.to_h.dup if override && !override.empty?

      client.environment(base)
    end

    private

    def checked_executable(path)
      expanded = File.expand_path(path)
      raise ArgumentError, "ZUI_HOST is not executable: #{expanded}" unless File.executable?(expanded)
      expanded
    end
  end
end
