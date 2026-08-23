# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class RestaurantDrinksAppTest < Minitest::Test
  def build_app
    RestaurantDrinks.build
  end

  def event(id, name, payload = {}, sequence = 1)
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

  def all_nodes(node)
    [node] + node.fetch("children", []).flat_map { |child| all_nodes(child) }
  end

  def test_builds_a_ruby_only_drink_menu_and_checkout
    app = build_app
    nodes = all_nodes(app.tree.fetch("main"))
    ids = nodes.map { |node| node.fetch("id") }

    assert_includes ids, "drink.still_water"
    assert_includes ids, "drink.sprite"
    assert_includes ids, "drink.diet_coke"
    assert_includes ids, "place_order"
    assert_includes ids, "future_pour_hero"
    assert_includes ids, "bar_progress"
    assert_equal 9, RestaurantDrinks::MENU.length
    RestaurantDrinks::MENU.each do |drink|
      image = nodes.find { |node| node["id"] == "drink.#{drink[:id]}.image" }
      refute_nil image, "missing menu image for #{drink[:name]}"
      assert_equal "image", image.fetch("type")
      assert_equal drink[:image], image.dig("props", "source")
      assert File.file?(File.expand_path("../#{drink[:image]}", __dir__)), "missing asset #{drink[:image]}"
    end
    assert_equal({}, app.state.cart)
  end

  def test_adds_drinks_changes_size_and_places_an_order
    app = build_app
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("drink.still_water.add", "click"))
    assert_equal({ "still_water:regular" => 1 }, app.state.cart)

    app.receive(event("size.large", "click", {}, 2))
    app.receive(event("drink.sprite.add", "click", {}, 3))
    assert_equal "Large", app.state.size
    assert_equal 1, app.state.cart.fetch("sprite:large")

    app.receive(event("place_order", "click", {}, 4))
    assert_equal({}, app.state.cart)
    assert_equal 1049, app.state.order_number
    assert_equal true, app.state.confirmation_open
    assert_equal "MIXING", app.state.bar_status
    assert_equal 12, app.state.bar_progress
    assert_includes app.state.last_receipt, "2 drinks"
    assert_includes app.state.last_receipt, "Table 12"
    assert_includes app.state.last_receipt, "Total:"
    assert output.string.lines.any? { |line| JSON.parse(line)["type"] == "patch" }
  ensure
    app&.stop
  end

  def test_filters_the_menu_from_the_search_field
    app = build_app
    app.start(output: StringIO.new, error: StringIO.new)

    app.receive(event("menu_search", "input", { "value" => "sprite" }))

    assert_equal "sprite", app.state.query
    menu = all_nodes(app.tree.fetch("main")).find { |node| node["id"] == "drink_menu" }
    assert_equal ["drink.sprite"], menu.fetch("children").map { |node| node.fetch("id") }
  ensure
    app&.stop
  end
end
