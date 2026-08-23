# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class ShaderStudioTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "activate", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_a_real_shader_pipeline
    app = ShaderStudio.build
    nodes = all(app.tree.fetch("main"))
    shader = nodes.find { |node| node["id"] == "live_shader" }
    assert_equal "shader_effect", shader.fetch("type")
    assert_equal "assets/shaders/golden-apollian.frag.qsb", shader.dig("props", "shader")
    assert_equal true, shader.dig("props", "running")
    assert_empty shader.fetch("children", [])
    ShaderStudio::SHADERS.each do |name|
      assert File.file?(File.expand_path("../assets/shaders/#{name.tr('_', '-')}.frag.qsb", __dir__))
    end
  end

  def test_library_selection_and_export_are_stateful
    app = ShaderStudio.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("shader.procedural_ocean"))
    app.receive(event("live_shader", "hover", "x" => 710, "y" => 184))
    app.receive(event("export_preset", "click"))
    assert_equal "procedural_ocean", app.state.shader
    assert_in_delta 710, app.state.mouse_x
    assert_in_delta 184, app.state.mouse_y
    assert_equal true, app.state.notice
  ensure
    app&.stop
  end
end
