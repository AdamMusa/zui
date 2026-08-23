# frozen_string_literal: true

# The native entrypoint evaluates this probe with the project directory as its
# require base, matching the packaged application loader.
require_relative "app"

application = RestaurantDrinks.build
raise "restaurant catalog is incomplete" unless RestaurantDrinks::MENU.length == 9
raise "main surface is missing" unless application.tree.key?("main")
raise "expanded DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:badge)
raise "GPU DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:shader_effect)
