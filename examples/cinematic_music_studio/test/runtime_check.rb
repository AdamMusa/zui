# frozen_string_literal: true

require_relative "app"

application = CinematicMusicStudio.build
raise "music studio surface missing" unless application.tree.key?("main")
