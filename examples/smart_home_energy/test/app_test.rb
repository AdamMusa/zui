# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class SmartHomeEnergyTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_the_image_backed_room_simulation
    app = SmartHomeEnergy.build
    nodes = all(app.tree.fetch("main"))
    ids = nodes.map { |node| node["id"] }
    %w[room_lighting_effect room_image room_blackout room_light_switch room_brightness_slider
       solar_gauge home_battery_gauge energy_mix_chart comfort_heatmap].each do |id|
      assert_includes ids, id
    end
    room = nodes.find { |node| node["id"] == "room_image" }
    assert_equal "image", room.fetch("type")
    assert_equal "assets/smart-living-room.png", room.dig("props", "source")
  end

  def test_room_lighting_changes_scene_brightness_and_power
    app = SmartHomeEnergy.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("room_light_switch", "change", "value" => false))
    assert_equal false, app.state.living_lights
    app.receive(event("room_brightness_slider", "change", "value" => 37))
    assert_equal true, app.state.living_lights
    assert_equal 37.0, app.state.light_level
    app.receive(event("scene.night"))
    assert_equal "Night", app.state.scene
    assert_equal 24, app.state.light_level
  ensure
    app&.stop
  end

  def test_scene_and_optimization_update_state
    app = SmartHomeEnergy.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("scene.away"))
    app.receive(event("optimize_energy"))
    assert_equal "Away", app.state.scene
    assert_equal true, app.state.optimized
    assert_equal 3.2, app.state.usage
  ensure
    app&.stop
  end
end
