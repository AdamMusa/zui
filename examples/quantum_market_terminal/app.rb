# frozen_string_literal: true

require "zui"

module QuantumMarketTerminal
  INK = "#05080b"
  PANEL = "#0b1117"
  PANEL_ALT = "#101820"
  BORDER = "#21303a"
  WHITE = "#eef6f7"
  MUTED = "#7f939b"
  MINT = "#38ef9d"
  RED = "#ff5c75"
  CYAN = "#42d9f5"
  GOLD = "#ffd166"
  VIOLET = "#9d7aff"

  WATCHLIST = [
    { symbol: "NVDA", name: "NVIDIA", price: "132.44", change: "+2.84%", color: MINT },
    { symbol: "TSLA", name: "Tesla", price: "247.19", change: "+1.32%", color: MINT },
    { symbol: "BTC", name: "Bitcoin", price: "68,421", change: "−0.41%", color: RED },
    { symbol: "ETH", name: "Ethereum", price: "3,742", change: "+3.07%", color: MINT },
    { symbol: "SOL", name: "Solana", price: "184.52", change: "+5.18%", color: MINT }
  ].freeze

  INITIAL_PRICES = {
    "NVDA" => 132.44, "TSLA" => 247.19, "BTC" => 68_421.0,
    "ETH" => 3_742.0, "SOL" => 184.52
  }.freeze

  INITIAL_POSITIONS = [
    { "symbol" => "NVDA", "qty" => 140.0, "avg" => 118.24 },
    { "symbol" => "ETH", "qty" => 3.4, "avg" => 3_221.0 },
    { "symbol" => "TSLA", "qty" => 48.0, "avg" => 231.80 }
  ].freeze

  CANDLES = [
    [118, 124, 116, 122], [122, 126, 120, 121], [121, 129, 120, 127], [127, 131, 124, 125],
    [125, 132, 124, 130], [130, 136, 128, 134], [134, 138, 130, 132], [132, 140, 131, 138],
    [138, 143, 135, 137], [137, 145, 136, 142], [142, 144, 137, 139], [139, 146, 138, 144],
    [144, 148, 141, 146], [146, 149, 142, 143], [143, 151, 142, 149], [149, 154, 147, 152]
  ].freeze

  module UI
    def market_price(symbol = state.symbol)
      state.prices.fetch(symbol.to_s, 0.0).to_f
    end

    def market_money(value)
      format("$%.2f", value.to_f)
    end

    def market_price_text(value)
      value.to_f >= 1_000 ? format("%.2f", value.to_f) : format("%.2f", value.to_f)
    end

    def market_portfolio_value
      value = state.cash.to_f
      state.positions.each do |position|
        value += position.fetch("qty").to_f * market_price(position.fetch("symbol"))
      end
      value
    end

    def market_position_rows
      state.positions.map do |position|
        symbol = position.fetch("symbol")
        quantity = position.fetch("qty").to_f
        average = position.fetch("avg").to_f
        pnl = (market_price(symbol) - average) * quantity
        {
          "symbol" => symbol,
          "qty" => quantity.round(4),
          "avg" => format("%.2f", average),
          "pnl" => format("%+.2f", pnl)
        }
      end
    end

    def market_candles_for(price)
      scale = price.to_f / 132.0
      QuantumMarketTerminal::CANDLES.map do |open_price, high, low, close|
        [open_price * scale, high * scale, low * scale, close * scale]
      end
    end

    def select_market_asset(asset)
      price = market_price(asset[:symbol])
      transaction do
        state.symbol = asset[:symbol]
        state.price = market_price_text(price)
        state.candles = market_candles_for(price)
        state.candle_min = price * 0.84
        state.candle_max = price * 1.18
      end
    end

    def execute_market_order
      side = state.order_side
      symbol = state.symbol
      quantity = state.order_quantity.to_f
      price = market_price(symbol)
      notional = quantity * price
      positions = state.positions.map(&:dup)
      position = positions.find { |candidate| candidate.fetch("symbol") == symbol }

      if quantity <= 0
        state.order_status = "REJECTED · quantity must be positive"
        return
      end

      if side == "BUY"
        if notional > state.cash.to_f
          state.order_status = "REJECTED · insufficient buying power"
          return
        end
        if position
          old_quantity = position.fetch("qty").to_f
          position["avg"] = ((position.fetch("avg").to_f * old_quantity) + notional) / (old_quantity + quantity)
          position["qty"] = old_quantity + quantity
        else
          positions << { "symbol" => symbol, "qty" => quantity, "avg" => price }
        end
        next_cash = state.cash.to_f - notional
      else
        if position.nil? || position.fetch("qty").to_f < quantity
          state.order_status = "REJECTED · insufficient position"
          return
        end
        position["qty"] = position.fetch("qty").to_f - quantity
        realized = (price - position.fetch("avg").to_f) * quantity
        positions.delete(position) if position.fetch("qty").to_f <= 0
        next_cash = state.cash.to_f + notional
        state.realized_pnl = state.realized_pnl.to_f + realized
      end

      transaction do
        state.positions = positions
        state.cash = next_cash
        state.order_count = state.order_count + 1
        state.order_status = "FILLED · #{side} #{quantity.round(4)} #{symbol} @ #{market_price_text(price)}"
        state.order_dialog = false
      end
    end

    def market_header
      rectangle width: 1392, height: 74, padding: 14, color: QuantumMarketTerminal::PANEL,
                radius: 18, border_color: QuantumMarketTerminal::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          rectangle width: 44, height: 44, radius: 12, color: "#102721",
                    border_color: QuantumMarketTerminal::MINT, border_width: 1 do
            text "Q", size: 20, bold: true, color: QuantumMarketTerminal::MINT, wrap: false
          end
          column spacing: 1, width: 340 do
            text "QUANTUM MARKET", size: 19, bold: true, color: QuantumMarketTerminal::WHITE, wrap: false
            text "MULTI-ASSET EXECUTION / SIMULATION", style: :caption,
                 color: QuantumMarketTerminal::MUTED, wrap: false
          end
          spacer width: 590
          chip "MARKET OPEN", icon: :clock, selected: true, background: "#10251d",
                              selected_background: "#10251d", foreground: QuantumMarketTerminal::MINT,
                              selected_foreground: QuantumMarketTerminal::MINT, accent: QuantumMarketTerminal::MINT
          column spacing: 1, width: 140 do
            text "PORTFOLIO", style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
            portfolio = text market_money(market_portfolio_value), id: :portfolio_value,
                             bold: true, color: QuantumMarketTerminal::WHITE, wrap: false
            bind(portfolio, :text) { market_money(market_portfolio_value) }
          end
          badge "+4.82%", size: 28, background: "#143125", foreground: QuantumMarketTerminal::MINT
        end
      end
    end

    def market_chart
      rectangle width: 900, height: 430, padding: 15, color: QuantumMarketTerminal::PANEL,
                radius: 20, border_color: QuantumMarketTerminal::BORDER, border_width: 1 do
        column spacing: 8 do
          row spacing: 10, alignment: :center do
            column spacing: 1, width: 430 do
              symbol = text "#{state.symbol} / USD", id: :active_symbol, size: 18, bold: true,
                            color: QuantumMarketTerminal::WHITE, wrap: false
              bind(symbol, :text) { "#{state.symbol} / USD" }
              price = text state.price, id: :active_price, size: 28, bold: true,
                           color: QuantumMarketTerminal::MINT, wrap: false
              bind(price, :text) { state.price }
            end
            column spacing: 1, width: 112 do
              text "ORDER QTY", style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
              quantity = spin_box state.order_quantity, id: :order_quantity,
                                  minimum: 1, maximum: 10_000, step: 1,
                                  width: 108, height: 34, editable: true,
                                  background: QuantumMarketTerminal::PANEL_ALT,
                                  foreground: QuantumMarketTerminal::WHITE,
                                  accent: QuantumMarketTerminal::CYAN do |event|
                state.order_quantity = event.fetch("value", state.order_quantity).to_f
              end
              bind(quantity, :value) { state.order_quantity }
            end
            %w[1H 1D 1W].each do |range|
              control = button range, id: "range.#{range.downcase}",
                               active: state.range == range, bordered: true,
                               foreground: state.range == range ? QuantumMarketTerminal::WHITE : QuantumMarketTerminal::MUTED,
                               background: state.range == range ? "#153025" : "transparent",
                               accent: QuantumMarketTerminal::MINT do
                state.range = range
              end
              bind(control, :active) { state.range == range }
              bind(control, :background) { state.range == range ? "#153025" : "transparent" }
            end
          end
          candles = candlestick_chart state.candles, id: :candlestick_chart,
                                      width: 868, height: 285, labels: (1..16).map(&:to_s),
                                      up_color: QuantumMarketTerminal::MINT,
                                      down_color: QuantumMarketTerminal::RED,
                                      wick_color: "#8ba0a7", grid_color: "#1c2d35",
                                      minimum: state.candle_min, maximum: state.candle_max,
                                      show_grid: true, candle_spacing: 7
          bind(candles, :values) { state.candles }
          bind(candles, :minimum) { state.candle_min }
          bind(candles, :maximum) { state.candle_max }
          row spacing: 22 do
            [["OPEN", "118.20"], ["HIGH", "154.08"], ["LOW", "116.42"], ["VOLUME", "84.2M"]].each do |label, value|
              column spacing: 1, width: 170 do
                text label, style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
                text value, bold: true, color: QuantumMarketTerminal::WHITE, wrap: false
              end
            end
            button "BUY", id: :buy_asset, icon: :plus, active: true, bordered: true,
                   foreground: QuantumMarketTerminal::INK, background: QuantumMarketTerminal::MINT,
                   accent: QuantumMarketTerminal::MINT do
              transaction do
                state.order_side = "BUY"
                state.order_dialog = true
              end
            end
            button "SELL", id: :sell_asset, icon: :minus, bordered: true,
                   foreground: QuantumMarketTerminal::RED, background: "transparent",
                   accent: QuantumMarketTerminal::RED do
              transaction do
                state.order_side = "SELL"
                state.order_dialog = true
              end
            end
          end
        end
      end
    end

    def market_watchlist
      rectangle width: 478, height: 430, padding: 14, color: QuantumMarketTerminal::PANEL,
                radius: 20, border_color: QuantumMarketTerminal::BORDER, border_width: 1 do
        column spacing: 8 do
          row spacing: 8, alignment: :center do
            text "WATCHLIST", size: 15, bold: true, width: 318,
                 color: QuantumMarketTerminal::WHITE, wrap: false
            badge "5", size: 24, background: "#16262c", foreground: QuantumMarketTerminal::CYAN
          end
          QuantumMarketTerminal::WATCHLIST.each do |asset|
            item = item_delegate asset[:symbol], id: "asset.#{asset[:symbol].downcase}", value: asset[:symbol],
                                 description: asset[:name], trailing_text: "#{asset[:price]}   #{asset[:change]}",
                                 width: 448, height: 62, padding: 11, spacing: 12,
                                 icon: :arrow_up, icon_color: asset[:color], icon_size: 18,
                                 selected: state.symbol == asset[:symbol], background: "transparent",
                                 selected_background: "#14241f", foreground: QuantumMarketTerminal::WHITE,
                                 selected_foreground: QuantumMarketTerminal::MINT,
                                 muted: QuantumMarketTerminal::MUTED,
                                 border_color: state.symbol == asset[:symbol] ? "#24593f" : "transparent" do
              select_market_asset(asset)
            end
            bind(item, :selected) { state.symbol == asset[:symbol] }
            bind(item, :border_color) { state.symbol == asset[:symbol] ? "#24593f" : "transparent" }
            bind(item, :trailing_text) do
              "#{market_price_text(market_price(asset[:symbol]))}   #{asset[:change]}"
            end
          end
          divider length: 448, color: QuantumMarketTerminal::BORDER
          row spacing: 12 do
            column spacing: 1, width: 210 do
              text "BUYING POWER", style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
              cash = text market_money(state.cash), id: :buying_power,
                          bold: true, color: QuantumMarketTerminal::WHITE, wrap: false
              bind(cash, :text) { market_money(state.cash) }
            end
            column spacing: 1 do
              text "RISK", style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
              text "MODERATE", bold: true, color: QuantumMarketTerminal::GOLD, wrap: false
            end
          end
        end
      end
    end

    def market_bottom
      row spacing: 14 do
        rectangle width: 330, height: 288, padding: 14, color: QuantumMarketTerminal::PANEL_ALT,
                  radius: 20, border_color: QuantumMarketTerminal::BORDER, border_width: 1 do
          column spacing: 8 do
            text "ALLOCATION", size: 15, bold: true, color: QuantumMarketTerminal::WHITE, wrap: false
            donut_chart [42, 26, 18, 14], id: :allocation_chart,
                        labels: %w[Equity Crypto Cash Bonds],
                        colors: [QuantumMarketTerminal::MINT, QuantumMarketTerminal::VIOLET,
                                 QuantumMarketTerminal::CYAN, QuantumMarketTerminal::GOLD],
                        width: 300, height: 190, inner_radius: 0.58,
                        center_text: "$248.9K", show_labels: false
            legend [{ label: "Equity", color: QuantumMarketTerminal::MINT },
                    { label: "Crypto", color: QuantumMarketTerminal::VIOLET },
                    { label: "Cash", color: QuantumMarketTerminal::CYAN },
                    { label: "Bonds", color: QuantumMarketTerminal::GOLD }],
                   orientation: :horizontal, width: 300, height: 40,
                   foreground: QuantumMarketTerminal::WHITE, muted: QuantumMarketTerminal::MUTED,
                   marker_size: 8, spacing: 10
          end
        end

        rectangle width: 620, height: 288, padding: 14, color: QuantumMarketTerminal::PANEL,
                  radius: 20, border_color: QuantumMarketTerminal::BORDER, border_width: 1 do
          column spacing: 8 do
            row spacing: 8, alignment: :center do
              text "OPEN POSITIONS", size: 15, bold: true, width: 430,
                   color: QuantumMarketTerminal::WHITE, wrap: false
              chip "LIVE P&L", selected: true, background: "#10251d",
                               selected_background: "#10251d", foreground: QuantumMarketTerminal::MINT,
                               selected_foreground: QuantumMarketTerminal::MINT,
                               accent: QuantumMarketTerminal::MINT
            end
            positions = data_table market_position_rows, id: :positions_table,
                       columns: [{ key: "symbol", label: "ASSET", width: 120 },
                                 { key: "qty", label: "QTY", width: 100 },
                                 { key: "avg", label: "AVG", width: 150 },
                                 { key: "pnl", label: "P&L", width: 160 }],
                       width: 590, height: 210, show_header: true, header_height: 42,
                       row_height: 50, alternating_rows: true, sort_column: 3,
                       sort_order: :descending, background: "transparent",
                       header_background: "#111d24", cell_background: "#0b1117",
                       alternate_background: "#0e161d", selected_background: "#183126",
                       foreground: QuantumMarketTerminal::WHITE,
                       header_foreground: QuantumMarketTerminal::MUTED,
                       selected_foreground: QuantumMarketTerminal::MINT,
                       grid_color: QuantumMarketTerminal::BORDER,
                       border_color: QuantumMarketTerminal::BORDER, font_size: 12, header_size: 10
            bind(positions, :rows) { market_position_rows }
          end
        end

        rectangle width: 414, height: 288, padding: 14, color: QuantumMarketTerminal::PANEL,
                  radius: 20, border_color: QuantumMarketTerminal::BORDER, border_width: 1 do
          column spacing: 8 do
            text "VOLATILITY PROFILE", size: 15, bold: true,
                 color: QuantumMarketTerminal::WHITE, wrap: false
            histogram [0.8, 1.1, 1.4, 0.9, 2.2, 1.7, 1.2, 2.8, 2.1, 1.9, 3.4, 2.6,
                       1.6, 1.3, 2.4, 3.0, 1.8, 2.0, 1.5, 2.7], id: :volatility_histogram,
                      bins: 8, width: 384, height: 150, color: QuantumMarketTerminal::VIOLET,
                      grid_color: "#20303a", minimum: 0, maximum: 4,
                      show_grid: true, bar_spacing: 5
            row spacing: 16 do
              radial_gauge [], value: 62, minimum: 0, maximum: 100,
                           width: 112, height: 92, color: QuantumMarketTerminal::GOLD,
                           track_color: "#302a1a", thickness: 8, label: "VaR",
                           label_format: "%{value}%"
              column spacing: 4 do
                text "BETA", style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
                text "1.18", bold: true, color: QuantumMarketTerminal::WHITE, wrap: false
                text "MAX DRAWDOWN", style: :caption, color: QuantumMarketTerminal::MUTED, wrap: false
                text "−6.4%", bold: true, color: QuantumMarketTerminal::RED, wrap: false
              end
            end
            order_status = text state.order_status, id: :latest_order_status,
                                style: :caption, bold: true, color: QuantumMarketTerminal::CYAN,
                                width: 380, wrap: false
            bind(order_status, :text) { state.order_status }
          end
        end
      end
    end

    def quantum_market_screen
      column spacing: 14 do
        market_header
        row spacing: 14, alignment: :start do
          market_chart
          market_watchlist
        end
        market_bottom
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :symbol, "NVDA"
      state :price, "132.44"
      state :range, "1D"
      state :candles, CANDLES
      state :candle_min, 110.0
      state :candle_max, 160.0
      state :prices, INITIAL_PRICES.dup
      state :positions, INITIAL_POSITIONS.map(&:dup)
      state :cash, 42_680.0
      state :realized_pnl, 0.0
      state :order_quantity, 10.0
      state :order_side, "BUY"
      state :order_count, 0
      state :order_status, "READY · paper execution only"
      state :market_tick, 0
      state :order_dialog, false

      app :main, title: "Quantum Market · Simulation", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        quantum_market_screen
        order = alert_dialog "Review paper order", "BUY 10 NVDA",
                             id: :order_dialog, severity: :info, opened: false, centered: true,
                             standard_buttons: %i[ok cancel], width: 480, height: 330,
                             informative_text: "Estimated value $1,324.40 · simulated execution",
                             background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                             foreground: WHITE, muted: MUTED, accent: MINT,
                             button_accent: MINT, border_color: BORDER
        bind(order, :opened) { state.order_dialog }
        bind(order, :message) do
          "#{state.order_side} #{state.order_quantity.round(4)} #{state.symbol} @ #{market_price_text(market_price)}"
        end
        bind(order, :informative_text) do
          "Estimated value #{market_money(state.order_quantity.to_f * market_price)} · paper execution only"
        end
        bind(order, :severity) { state.order_side == "BUY" ? "success" : "warning" }
        on(order, :accept) { execute_market_order }
        on(order, :reject) { state.order_dialog = false }
        on(order, :close) { state.order_dialog = false }
      end

      every(0.9) do
        tick = state.market_tick + 1
        direction = tick.even? ? 1.0 : -1.0
        step = [market_price * 0.0007, 0.01].max
        next_price = [market_price + direction * step, 0.01].max
        next_prices = state.prices.merge(state.symbol => next_price)
        next_candles = state.candles.map(&:dup)
        previous_close = next_candles.last[3].to_f
        next_candles = next_candles.drop(1) + [[previous_close, [previous_close, next_price].max * 1.003,
                                               [previous_close, next_price].min * 0.997, next_price]]
        transaction do
          state.market_tick = tick
          state.prices = next_prices
          state.price = market_price_text(next_price)
          state.candles = next_candles
          state.candle_min = [state.candle_min.to_f, next_price * 0.94].min
          state.candle_max = [state.candle_max.to_f, next_price * 1.06].max
        end
      end
    end
  end

  def self.run = build.run
end
