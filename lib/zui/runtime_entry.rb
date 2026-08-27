# frozen_string_literal: true

module Zui
  VERSION = "0.0.10"
  FRAMEWORK_ROOT = File.expand_path("../..", __dir__)
end

require_relative "protocol"
require_relative "value"
require_relative "state_store"
require_relative "node"
require_relative "animation"
require_relative "scheduler"
require_relative "component_registry"
require_relative "components"
require_relative "builder"
require_relative "application"

module Zui
  def self.app(&definition)
    Application.new(&definition).run
  end

  class << self
    alias application app
  end
end
