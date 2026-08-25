# frozen_string_literal: true

require "json"

module Zui
  class ApplicationRuntime
    FORMAT = 1

    attr_reader :engine, :version, :executable, :environment, :gems

    def initialize(engine:, version:, executable:, environment: {}, gems: [])
      @engine = engine.to_s
      @version = version.to_s
      @executable = executable.to_s
      @environment = environment.transform_keys(&:to_s).transform_values do |paths|
        Array(paths).map(&:to_s).freeze
      end.freeze
      @gems = Array(gems).map(&:to_s).sort.freeze
      freeze
    end

    def write(directory)
      File.write(File.join(directory, "runtime.json"), "#{JSON.pretty_generate(to_h)}\n")
      self
    end

    def to_h
      {
        "format" => FORMAT,
        "engine" => engine,
        "version" => version,
        "executable" => executable,
        "environment" => environment,
        "gems" => gems
      }
    end
  end
end
