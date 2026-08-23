# frozen_string_literal: true

require_relative "app"

application = SmartHomeEnergy.build
raise "smart home surface missing" unless application.tree.key?("main")
