# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class CardiacHealthMonitorTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_the_visual_health_surface
    app = CardiacHealthMonitor.build
    nodes = all(app.tree.fetch("main"))
    ids = nodes.map { |node| node["id"] }
    %w[heart_image heart_render_mode heart_particles
       ecg_waveform bpm.gauge recovery_heatmap insight_dialog].each do |id|
      assert_includes ids, id
    end
    heart = nodes.find { |node| node["id"] == "heart_image" }
    assert_equal "image", heart.fetch("type")
    assert_equal "assets/luminous-heart.png", heart.dig("props", "source")
    assert_equal "preserve_aspect_crop", heart.dig("props", "fill_mode")
    refute nodes.any? { |node| node["type"] == "model_view_3d" }
    refute_includes ids, "heart_reset"
    refute_includes ids, "heart_zoom_readout"
  end

  def test_breathing_and_insight_controls_are_stateful
    app = CardiacHealthMonitor.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("breathing_toggle"))
    app.receive(event("daily_insight"))
    assert_equal true, app.state.breathing
    assert_equal true, app.state.insight_dialog
  ensure
    app&.stop
  end
end
