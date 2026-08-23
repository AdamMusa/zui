# frozen_string_literal: true

# The native entrypoint evaluates this probe with the project directory as its
# require base, matching the packaged application loader.
require_relative "app"

application = FuturisticDashboard.build
raise "main surface is missing" unless application.tree.key?("main")
raise "gauge DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:radial_gauge)
raise "GPU DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:particle_system)
raise "image DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:image)
