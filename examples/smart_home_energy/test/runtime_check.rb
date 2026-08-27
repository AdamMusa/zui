# frozen_string_literal: true

require "smart_home_energy"
require_relative "../app"

application = SmartHomeEnergy.build
raise "smart home project gem missing" unless SmartHomeEnergy::PROJECT_GEM
raise "smart home surface missing" unless application.tree.key?("main")
