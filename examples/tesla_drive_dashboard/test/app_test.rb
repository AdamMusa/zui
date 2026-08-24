# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require "timeout"
require_relative "../app"

class TeslaDriveDashboardTest < Minitest::Test
  def nodes(node)
    [node] + node.fetch("children", []).flat_map { |child| nodes(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_the_complete_cockpit
    app = TeslaDriveDashboard.build
    all = nodes(app.tree.fetch("main"))
    ids = all.map { |node| node["id"] }
    %w[drive_media_player destination_search emergency_switch vehicle_hero_image vehicle_speed
       route_map drive_gear autopilot_switch cabin_temperature battery_gauge power_curve
       climate_switch vehicle_media_progress charge_dialog vehicle_motion_particles
       left_camera right_camera drive_power drive_traction
       drive_camera drive_range drive_route_left].each do |id|
      assert_includes ids, id
    end
    refute_includes ids, "hero_drive_state"
    refute_includes ids, "vehicle_view_label"
    hero = all.find { |node| node["id"] == "vehicle_hero_image" }
    assert_equal "assets/electric-grand-tourer.png", hero.dig("props", "source")
    assert_equal "preserve_aspect_crop", hero.dig("props", "fill_mode")
    assert_equal 516, hero.dig("props", "width")
    assert_equal 194, hero.dig("props", "height")
    assert_equal false, app.state.driving
    assert_equal 0, app.state.speed
    TeslaDriveDashboard::VEHICLE_VIEWS.each do |source|
      assert File.file?(File.join(__dir__, "..", source)), "missing vehicle view: #{source}"
    end
    %w[vehicle-trunk-open.png vehicle-charge-open.png].each do |asset|
      assert File.file?(File.join(__dir__, "..", "assets", asset)), "missing vehicle state: #{asset}"
    end
    player = all.find { |node| node["id"] == "drive_media_player" }
    assert_equal "assets/cockpit-loop.ogg", player.dig("props", "source")
  end

  def test_drive_controls_update_ruby_state
    app = TeslaDriveDashboard.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("mode.standard"))
    app.receive(event("vehicle_lock"))
    app.receive(event("plan_charge"))
    assert_equal "Standard", app.state.mode
    assert_equal false, app.state.locked
    assert_equal true, app.state.charge_dialog
  ensure
    app&.stop
  end


  def test_center_display_controls_drive_real_simulation_state
    app = TeslaDriveDashboard.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("temperature_up"))
    app.receive(event("seat_heat"))
    app.receive(event("autopilot_switch", "change", "value" => false))
    app.receive(event("right_camera"))
    hero = nodes(app.tree.fetch("main")).find { |node| node["id"] == "vehicle_hero_image" }
    assert_equal 1, app.state.vehicle_view
    assert_equal "assets/vehicle-front.png", hero.dig("props", "source")

    app.receive(event("charge_port_toggle"))
    assert_equal 21.5, app.state.cabin_temperature
    assert_equal 2, app.state.seat_heat
    assert_equal false, app.state.autopilot
    assert_equal true, app.state.charge_port_open
    assert_equal "assets/vehicle-charge-open.png", hero.dig("props", "source")
    assert_equal false, app.state.driving

    app.receive(event("trunk_toggle"))
    assert_equal false, app.state.charge_port_open
    assert_equal true, app.state.trunk_open
    assert_equal "assets/vehicle-trunk-open.png", hero.dig("props", "source")

    app.receive(event("drive_toggle"))
    assert_equal true, app.state.driving
    assert_equal false, app.state.trunk_open
    assert_equal false, app.state.charge_port_open
    assert_equal "assets/vehicle-front.png", hero.dig("props", "source")
    Timeout.timeout(2) do
      sleep(0.02) until app.state.speed.positive? && app.state.trip_distance.positive?
    end
    assert_operator app.state.speed, :>, 0
    assert_operator app.state.trip_distance, :>, 0
    power = nodes(app.tree.fetch("main")).find { |node| node["id"] == "drive_power" }
    assert_equal "#{(app.state.speed * 2.4).round} kW", power.dig("props", "text")
  ensure
    app&.stop
  end
end
