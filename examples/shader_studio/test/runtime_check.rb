# frozen_string_literal: true

require_relative "app"

application = ShaderStudio.build
raise "shader studio surface missing" unless application.tree.key?("main")
