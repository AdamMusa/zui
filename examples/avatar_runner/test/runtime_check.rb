# frozen_string_literal: true

require_relative "../app"

application = AvatarRunner.build
raise "avatar runner surface missing" unless application.tree.key?("main")
raise "Canvas DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:canvas)
raise "keyboard DSL runtime is stale" unless Zui::Builder.instance_methods.include?(:key_catcher)
