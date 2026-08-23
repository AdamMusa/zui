# frozen_string_literal: true

require_relative "app"

application = TeslaDriveDashboard.build
raise "tesla drive surface missing" unless application.tree.key?("main")
