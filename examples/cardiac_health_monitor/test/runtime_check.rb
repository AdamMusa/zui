# frozen_string_literal: true

require_relative "app"

application = CardiacHealthMonitor.build
raise "cardiac health surface missing" unless application.tree.key?("main")
