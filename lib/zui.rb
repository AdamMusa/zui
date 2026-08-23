# frozen_string_literal: true

require_relative "zui/protocol"
require_relative "zui/value"
require_relative "zui/state_store"
require_relative "zui/node"
require_relative "zui/animation"
require_relative "zui/scheduler"
require_relative "zui/command"
require_relative "zui/component_registry"
require_relative "zui/components"
require_relative "zui/builder"
require_relative "zui/application"
require_relative "zui/source_bundle"

module Zui
  VERSION = "0.1.0"
  FRAMEWORK_ROOT = File.expand_path("..", __dir__)

  def self.app(&definition)
    Application.new(&definition).run
  end

  class << self
    alias application app
  end
end
