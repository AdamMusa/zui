# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class OrbitalWeatherConsoleTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_the_orbital_weather_surface
    app = OrbitalWeatherConsole.build
    nodes = all(app.tree.fetch("main"))
    ids = nodes.map { |node| node["id"] }
    %w[weather_layer_effect storm_image atmosphere_particles weather_scan_switch storm_radar
       pressure_chart impact_heatmap briefing_dialog].each do |id|
      assert_includes ids, id
    end
    assert_equal "assets/orbital-storm.png", nodes.find { |node| node["id"] == "storm_image" }.dig("props", "source")
  end

  def test_layer_and_briefing_controls_update_state
    app = OrbitalWeatherConsole.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("layer.moisture"))
    app.receive(event("issue_briefing"))
    assert_equal "Moisture", app.state.layer
    assert_equal true, app.state.briefing
    assert_equal 1, app.state.layer_changes
  ensure
    app&.stop
  end


  def test_scan_and_share_controls_change_the_live_model
    app = OrbitalWeatherConsole.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("weather_scan_switch", "change", "value" => false))
    app.receive(event("share_track"))
    assert_equal false, app.state.scanning
    assert_equal 1, app.state.share_count
  ensure
    app&.stop
  end
end
