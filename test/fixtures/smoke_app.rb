# frozen_string_literal: true

require "zui"

Zui.app do
  state :count, 0

  app :main, title: "Zui Linux Smoke Test", width: 480, height: 320 do
    container padding: 24 do
      column spacing: 12 do
        text "Standalone Zui", style: :heading
        counter = text "Count: 0", id: :counter
        bind(counter, :text) { "Count: #{state.count}" }
        button "Increment", id: :increment do
          state.count += 1
        end
        radar_chart [[3, 5, 4]], labels: %w[UI State Events], width: 140, height: 100
      end
    end
  end
end
