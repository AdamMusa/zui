# frozen_string_literal: true

require_relative "app"

application = QuantumMarketTerminal.build
raise "market terminal surface missing" unless application.tree.key?("main")
