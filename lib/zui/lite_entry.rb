# frozen_string_literal: true

module Zui
  class EmbeddedOutput
    def initialize(error: false)
      @error = error
    end

    def puts(*values)
      values.each do |value|
        line = value.nil? ? "" : value.to_s
        @error ? ZuiNative.emit_error(line) : ZuiNative.emit(line)
      end
      nil
    end

    def sync=(_value)
      true
    end
  end

  def self.app(&definition)
    application = Application.new(&definition)
    return application.run unless Object.const_defined?(:ZuiNative)

    start_embedded(application)
  end

  def self.start_embedded(application)
    @embedded_application = application
    application.start(output: EmbeddedOutput.new, error: EmbeddedOutput.new(error: true))
  end

  def self.embedded_receive(line)
    raise "embedded Zui application is not running" unless @embedded_application

    @embedded_application.receive(line.to_s)
  end

  def self.embedded_stop
    @embedded_application&.stop
    @embedded_application = nil
  end

  class << self
    alias application app
  end
end
