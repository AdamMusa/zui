# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class FuturisticDashboardAppTest < Minitest::Test
  def build_app
    FuturisticDashboard.build
  end

  def all_nodes(node)
    [node] + node.fetch("children", []).flat_map { |child| all_nodes(child) }
  end

  def event(id, name = "click", payload = {}, sequence = 1)
    JSON.generate(
      "v" => Zui::PROTOCOL_VERSION,
      "type" => "event",
      "surface" => "main",
      "id" => id,
      "event" => name,
      "seq" => sequence,
      "payload" => payload
    )
  end

  def test_builds_a_ruby_only_gpu_dashboard
    app = build_app
    nodes = all_nodes(app.tree.fetch("main"))
    ids = nodes.map { |node| node.fetch("id") }

    %w[neural_core_image hero_particles throughput_chart system_radar shield_gauge power_gauge
       scan_button boost_button scan_result_dialog].each do |id|
      assert_includes ids, id
    end

    image = nodes.find { |node| node["id"] == "neural_core_image" }
    assert_equal "assets/neural-core.svg", image.dig("props", "source")
    assert_equal "preserve_aspect_fit", image.dig("props", "fill_mode")

    overview = nodes.find { |node| node["id"] == "nav.overview" }
    assert_equal 14, overview.dig("props", "spacing")

    dialog = nodes.find { |node| node["id"] == "scan_result_dialog" }
    assert_equal true, dialog.dig("props", "centered")
  end

  def test_navigation_and_overdrive_are_stateful
    app = build_app
    app.start(output: StringIO.new, error: StringIO.new)

    app.receive(event("nav.star_map", "activate", { "value" => "Star map" }))
    assert_equal "Star map", app.state.active_section

    app.receive(event("boost_button"))
    assert_equal true, app.state.boost
    assert_equal 96, app.state.power
    assert_equal "Overdrive engaged", app.state.events.first.fetch(:title)
  ensure
    app&.stop
  end

  def test_scan_enters_the_active_state
    app = build_app
    app.start(output: StringIO.new, error: StringIO.new)

    app.receive(event("scan_button"))

    assert_equal true, app.state.scan_active
    assert_equal 0, app.state.threats
    assert_equal "Deep scan started", app.state.events.first.fetch(:title)
  ensure
    app&.stop
  end
end
