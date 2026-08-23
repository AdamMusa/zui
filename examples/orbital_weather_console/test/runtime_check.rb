# frozen_string_literal: true

require_relative "app"

application = OrbitalWeatherConsole.build
raise "orbital weather surface missing" unless application.tree.key?("main")
