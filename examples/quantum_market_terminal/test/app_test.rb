# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class QuantumMarketTerminalTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "activate", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_the_market_catalog_surface
    app = QuantumMarketTerminal.build
    ids = all(app.tree.fetch("main")).map { |node| node["id"] }
    %w[candlestick_chart allocation_chart positions_table volatility_histogram order_dialog].each do |id|
      assert_includes ids, id
    end
  end

  def test_watchlist_and_order_controls_update_state
    app = QuantumMarketTerminal.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("asset.eth"))
    app.receive(event("buy_asset", "click"))
    assert_equal "ETH", app.state.symbol
    assert_equal "3742.00", app.state.price
    assert_equal true, app.state.order_dialog
  ensure
    app&.stop
  end


  def test_buy_and_sell_orders_change_cash_positions_and_history
    app = QuantumMarketTerminal.build
    app.start(output: StringIO.new, error: StringIO.new)
    opening_cash = app.state.cash
    opening_quantity = app.state.positions.find { |position| position["symbol"] == "NVDA" }["qty"]

    app.receive(event("order_quantity", "change", "value" => 2))
    app.receive(event("buy_asset", "click"))
    app.receive(event("order_dialog", "accept"))
    bought = app.state.positions.find { |position| position["symbol"] == "NVDA" }
    assert_equal opening_quantity + 2, bought["qty"]
    assert_operator app.state.cash, :<, opening_cash
    assert_match(/FILLED · BUY/, app.state.order_status)

    cash_after_buy = app.state.cash
    app.receive(event("sell_asset", "click"))
    app.receive(event("order_dialog", "accept"))
    sold = app.state.positions.find { |position| position["symbol"] == "NVDA" }
    assert_equal opening_quantity, sold["qty"]
    assert_operator app.state.cash, :>, cash_after_buy
    assert_equal 2, app.state.order_count
  ensure
    app&.stop
  end
end
