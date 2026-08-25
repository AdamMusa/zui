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
require_relative "zui/platform"
require_relative "zui/runtime"
require_relative "zui/tree_shaker"
require_relative "zui/dist_config"
require_relative "zui/client"
require_relative "zui/host"
require_relative "zui/runner"
require_relative "zui/generator"
require_relative "zui/distribution"
require_relative "zui/dist_packager"

module Zui
  VERSION = "0.0.7"
  FRAMEWORK_ROOT = File.expand_path("..", __dir__)

  def self.app(&definition)
    Application.new(&definition).run
  end

  class << self
    alias application app
  end
end
