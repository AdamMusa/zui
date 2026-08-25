# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class AvatarRunnerTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_a_canvas_game_with_keyboard_and_pointer_input
    application = AvatarRunner.build
    nodes = all(application.tree.fetch("main"))
    canvas = nodes.find { |node| node["id"] == "game_canvas" }
    keyboard = nodes.find { |node| node["id"] == "runner_keys" }

    assert_equal "canvas", canvas.fetch("type")
    assert_equal AvatarRunner::WIDTH, canvas.dig("props", "width")
    assert_equal AvatarRunner::HEIGHT, canvas.dig("props", "height")
    assert_operator canvas.dig("props", "commands").length, :>, 50
    assert_includes canvas.fetch("events"), "click"
    assert_equal "key_catcher", keyboard.fetch("type")
    %w[activate return move close text].each { |name| assert_includes keyboard.fetch("events"), name }
  ensure
    application&.stop
  end

  def test_keyboard_input_starts_the_run_and_jumps
    application = AvatarRunner.build
    application.start(output: StringIO.new, error: StringIO.new)

    application.receive(event("runner_keys", "activate"))

    assert_equal "running", application.state.phase
    assert_operator application.state.velocity, :<, 0
  ensure
    application&.stop
  end

  def test_action_button_starts_and_escape_pauses_the_run
    application = AvatarRunner.build
    application.start(output: StringIO.new, error: StringIO.new)

    application.receive(event("runner_action"))
    assert_equal "running", application.state.phase

    application.receive(event("runner_keys", "close"))
    assert_equal "paused", application.state.phase
  ensure
    application&.stop
  end
end
