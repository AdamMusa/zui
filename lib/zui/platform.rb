# frozen_string_literal: true

require "rbconfig"

module Zui
  Platform = Struct.new(:os, :arch, keyword_init: true) do
    SUPPORTED_OSES = %i[linux macos windows].freeze

    def self.current
      detect(RbConfig::CONFIG.fetch("host_os"), RbConfig::CONFIG.fetch("host_cpu"))
    end

    def self.detect(host_os, host_cpu)
      os = case host_os.to_s
           when /darwin|mac\s?os/i then :macos
           when /linux/i then :linux
           when /mswin|mingw|cygwin|windows/i then :windows
           else :unsupported
           end
      arch = case host_cpu.to_s
             when /aarch64|arm64/i then :arm64
             when /x86_64|amd64|x64/i then :x86_64
             else host_cpu.to_s.downcase.gsub(/[^a-z0-9_]+/, "_").to_sym
             end
      new(os:, arch:)
    end

    def supported? = SUPPORTED_OSES.include?(os)
    def id = "#{os}-#{arch}"
    def linux? = os == :linux
    def macos? = os == :macos
    def windows? = os == :windows

    def assert_supported!
      return self if supported?

      raise ArgumentError, "Zui desktop applications support Linux, macOS, and Windows; detected #{os}/#{arch}"
    end
  end
end
