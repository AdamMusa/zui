# frozen_string_literal: true

module RestaurantDrinks
  MENU = [
    { id: "still_water", name: "Still Water", category: "Water", image: "assets/still-water.png", color: "#77c9ff", price: 250,
      description: "Chilled filtered water" },
    { id: "sparkling_water", name: "Sparkling Water", category: "Water", image: "assets/sparkling-water.png", color: "#75e6da", price: 325,
      description: "Bright mineral bubbles" },
    { id: "coca_cola", name: "Coca-Cola", category: "Soda", image: "assets/coca-cola.png", color: "#ff5f57", price: 350,
      description: "The original ice-cold classic" },
    { id: "diet_coke", name: "Diet Coke", category: "Soda", image: "assets/diet-coke.png", color: "#d7dee8", price: 350,
      description: "Crisp, light and sugar-free" },
    { id: "sprite", name: "Sprite", category: "Soda", image: "assets/sprite.png", color: "#70e17b", price: 350,
      description: "Lemon-lime refreshment" },
    { id: "ginger_ale", name: "Ginger Ale", category: "Soda", image: "assets/ginger-ale.png", color: "#e9bd61", price: 375,
      description: "Golden, dry and gently spiced" },
    { id: "lemonade", name: "House Lemonade", category: "Juice", image: "assets/house-lemonade.png", color: "#ffe36e", price: 425,
      description: "Fresh lemon with a clean finish" },
    { id: "orange_juice", name: "Orange Juice", category: "Juice", image: "assets/orange-juice.png", color: "#ffad52", price: 450,
      description: "Cold-pressed orange juice" },
    { id: "iced_tea", name: "Iced Tea", category: "Tea", image: "assets/iced-tea.png", color: "#cf8b52", price: 375,
      description: "Fresh-brewed black tea over ice" }
  ].freeze

  CATEGORIES = ["All", "Water", "Soda", "Juice", "Tea"].freeze
  SIZES = ["Regular", "Large"].freeze
  LARGE_UPCHARGE = 125
  TAX_RATE_BASIS_POINTS = 825

  module UI
    def restaurant_money(cents)
      value = cents.to_i
      dollars = value / 100
      pennies = value % 100
      "$#{dollars}.#{pennies < 10 ? "0#{pennies}" : pennies}"
    end

    def restaurant_cart_key(drink_id, size)
      "#{drink_id}:#{size.downcase}"
    end

    def restaurant_drink(drink_id)
      RestaurantDrinks::MENU.find { |drink| drink[:id] == drink_id }
    end

    def restaurant_line_details(key)
      parts = key.split(":")
      drink = restaurant_drink(parts[0])
      size = parts[1] == "large" ? "Large" : "Regular"
      [drink, size]
    end

    def restaurant_unit_price(drink, size)
      drink[:price] + (size == "Large" ? RestaurantDrinks::LARGE_UPCHARGE : 0)
    end

    def restaurant_item_count
      count = 0
      state.cart.each_value { |quantity| count += quantity.to_i }
      count
    end

    def restaurant_subtotal
      total = 0
      state.cart.each do |key, quantity|
        drink, size = restaurant_line_details(key)
        total += restaurant_unit_price(drink, size) * quantity.to_i if drink
      end
      total
    end

    def restaurant_totals
      subtotal = restaurant_subtotal
      tax = (subtotal * RestaurantDrinks::TAX_RATE_BASIS_POINTS + 5_000) / 10_000
      tip = (subtotal * state.tip_percent.to_i + 50) / 100
      { subtotal: subtotal, tax: tax, tip: tip, total: subtotal + tax + tip }
    end

    def restaurant_adjust(drink_id, size, amount)
      key = restaurant_cart_key(drink_id, size)
      next_cart = state.cart.dup
      quantity = next_cart.fetch(key, 0).to_i + amount.to_i
      if quantity <= 0
        next_cart.delete(key)
      else
        next_cart[key] = [quantity, 12].min
      end
      state.cart = next_cart
    end

    def restaurant_filtered_menu
      query = state.query.to_s.downcase
      category = state.category.to_s
      RestaurantDrinks::MENU.select do |drink|
        category_match = category == "All" || drink[:category] == category
        search_text = "#{drink[:name]} #{drink[:category]} #{drink[:description]}".downcase
        category_match && (query.empty? || search_text.include?(query))
      end
    end

    def restaurant_header
      stack width: 1170, height: 124 do
        image "assets/future-pour-bar.jpg", id: :future_pour_hero, width: 1170, height: 124,
              fill_mode: :preserve_aspect_crop, asynchronous: true, cache: true, mipmap: true
        rectangle width: 1170, height: 124, color: "#c4071310", radius: 22, padding: 18,
                  border_color: "#315c50", border_width: 1 do
          row spacing: 16, alignment: :center do
            gradient colors: ["#64f5bf", "#52d9ff", "#f6ce73"], type: :conical,
                     width: 54, height: 54, radius: 17
            column spacing: 2, width: 330 do
              text "NOVA POUR", size: 22, bold: true, color: "#f7fffc", wrap: false
              text "FUTURE BEVERAGE SERVICE · TABLE 12", style: :caption,
                   color: "#9ec8bc", wrap: false
            end
            spacer width: 410
            column spacing: 4, width: 145 do
              text "BAR TELEMETRY", style: :caption, color: "#7fa99e", wrap: false
              status = text state.bar_status, id: :bar_status, bold: true,
                            color: "#64f5bf", wrap: false
              bind(status, :text) { state.bar_status }
              progress_bar = progress state.bar_progress, id: :bar_progress, minimum: 0, maximum: 100,
                                      width: 130, height: 5, color: "#64f5bf"
              bind(progress_bar, :value) { state.bar_progress }
            end
            column spacing: 2, width: 116 do
              text "CURRENT TRAY", style: :caption, color: "#8fa69f", wrap: false
              count = text "#{restaurant_item_count} drinks", id: :header_order_text,
                           bold: true, color: "#f4fbf8", wrap: false
              bind(count, :text) do
                "#{restaurant_item_count} drink#{restaurant_item_count == 1 ? "" : "s"}"
              end
            end
            order_badge = badge restaurant_item_count, id: :header_order_count, size: 38, minimum_width: 38,
                                background: "#64f5bf", foreground: "#07110e"
            bind(order_badge, :value) { restaurant_item_count }
          end
        end
      end
    end

    def restaurant_toolbar
      rectangle width: 1170, height: 60, color: "#101d1a", radius: 16, padding: 10,
                border_color: "#263f38", border_width: 1 do
        row spacing: 16, alignment: :center do
          search = text_field state.query, id: :menu_search, placeholder: "Search the drink matrix…", width: 280,
                              foreground: "#f4fbf8", accent: "#64f5bf" do |event|
            state.query = event.fetch("value", "").to_s
          end
          bind(search, :text) { state.query }

          dynamic type: :row, id: :category_filters, spacing: 8, alignment: :center do
            RestaurantDrinks::CATEGORIES.each do |category|
              chip category, id: "category.#{category.downcase}", selected: state.category == category,
                             background: "#162723", selected_background: "#64f5bf",
                             foreground: "#cbd9d4", selected_foreground: "#07110e", accent: "#64f5bf" do
                state.category = category
              end
            end
          end

          spacer width: 12
          text "VESSEL", style: :caption, color: "#8fa69f", wrap: false
          dynamic type: :row, id: :size_filters, spacing: 8, alignment: :center do
            RestaurantDrinks::SIZES.each do |size|
              chip size, id: "size.#{size.downcase}", selected: state.size == size,
                         background: "#162723", selected_background: "#f6ce73",
                         foreground: "#cbd9d4", selected_foreground: "#171207", accent: "#f6ce73" do
                state.size = size
              end
            end
          end
        end
      end
    end

    def restaurant_drink_card(drink)
      key = restaurant_cart_key(drink[:id], state.size)
      quantity = state.cart.fetch(key, 0).to_i
      unit_price = restaurant_unit_price(drink, state.size)

      card id: "drink.#{drink[:id]}", width: 245, height: 244, padding: 14, spacing: 8,
           color: "#16231f", border_color: quantity.positive? ? drink[:color] : "#2c4039", accent: drink[:color] do
        row spacing: 10, alignment: :center do
          image drink[:image], id: "drink.#{drink[:id]}.image", width: 72, height: 72,
                fill_mode: :preserve_aspect_crop, asynchronous: true, cache: true,
                smooth: true, mipmap: true
          column spacing: 2 do
            text drink[:name], bold: true, size: 15, width: 130, color: "#f4fbf8", wrap: true
            text drink[:category], style: :caption, color: drink[:color], wrap: false
          end
        end
        text drink[:description], style: :caption, width: 206, color: "#93aaa2", wrap: true
        divider length: 206, color: "#31443e", opacity: 0.8
        row spacing: 8, alignment: :center do
          column spacing: 1 do
            text restaurant_money(unit_price), bold: true, color: "#f4fbf8", wrap: false
            text state.size, style: :caption, color: "#839991", wrap: false
          end
          spacer width: quantity.positive? ? 48 : 68
          if quantity.positive?
            round_button "−", id: "drink.#{drink[:id]}.minus", diameter: 32,
                              background: "#22342e", foreground: "#f4fbf8", accent: drink[:color] do
              restaurant_adjust(drink[:id], state.size, -1)
            end
            badge quantity, id: "drink.#{drink[:id]}.quantity", size: 28, minimum_width: 28,
                            background: drink[:color], foreground: "#08100e"
          end
          round_button quantity.positive? ? "+" : "Add", id: "drink.#{drink[:id]}.add",
                       diameter: quantity.positive? ? 32 : 52, background: drink[:color],
                       foreground: "#08100e", accent: drink[:color], font_size: quantity.positive? ? 15 : 12 do
            restaurant_adjust(drink[:id], state.size, 1)
          end
        end
      end
    end

    def restaurant_menu
      scroll width: 790, height: 555, clip: true do
        dynamic type: :grid, id: :drink_menu, columns: 3, spacing: 16 do
          drinks = restaurant_filtered_menu
          if drinks.empty?
            card width: 760, height: 150, padding: 24, color: "#16231f", border_color: "#2c4039" do
              text "No drinks found", style: :heading, color: "#f4fbf8"
              text "Try another search or category.", color: "#93aaa2"
            end
          else
            drinks.each { |drink| restaurant_drink_card(drink) }
          end
        end
      end
    end

    def restaurant_cart_line(key, quantity)
      drink, size = restaurant_line_details(key)
      return unless drink

      unit_price = restaurant_unit_price(drink, size)
      row spacing: 8, alignment: :center do
        rectangle width: 8, height: 42, color: drink[:color], radius: 4
        column spacing: 1, width: 156 do
          text drink[:name], bold: true, size: 13, width: 156, color: "#f4fbf8", wrap: false
          text "#{size} · #{restaurant_money(unit_price * quantity.to_i)}", style: :caption,
               color: "#8fa69f", wrap: false
        end
        round_button "−", id: "cart.#{drink[:id]}.#{size.downcase}.minus", diameter: 28,
                          background: "#22342e", foreground: "#f4fbf8", accent: drink[:color] do
          restaurant_adjust(drink[:id], size, -1)
        end
        badge quantity, id: "cart.#{drink[:id]}.#{size.downcase}.quantity", size: 25,
                        minimum_width: 25, background: drink[:color], foreground: "#08100e"
        round_button "+", id: "cart.#{drink[:id]}.#{size.downcase}.add", diameter: 28,
                          background: drink[:color], foreground: "#08100e", accent: drink[:color] do
          restaurant_adjust(drink[:id], size, 1)
        end
      end
    end

    def restaurant_submit_order
      totals = restaurant_totals
      next_number = state.order_number.to_i + 1
      service = state.service_type
      location = service == "Dine in" ? "Table #{state.table_number}" : "Takeaway"
      count = restaurant_item_count
      receipt = "#{count} drink#{count == 1 ? "" : "s"} · #{location}\nTotal: #{restaurant_money(totals[:total])}"

      transaction do
        state.order_number = next_number
        state.last_receipt = receipt
        state.cart = {}
        state.confirmation_open = true
        state.bar_progress = 12
        state.bar_status = "MIXING"
      end
    end

    def restaurant_cart
      card width: 360, height: 555, padding: 18, spacing: 12, color: "#111d1a",
           border_color: "#2c4039", accent: "#69d3a7" do
        row spacing: 10, alignment: :center do
          text "Your order", style: :heading, color: "#f4fbf8", wrap: false
          spacer width: 110
          dynamic type: :row, id: :cart_count, spacing: 5, alignment: :center do
            badge restaurant_item_count, size: 26, minimum_width: 26, background: "#69d3a7", foreground: "#07110e"
            text "items", style: :caption, color: "#8fa69f", wrap: false
          end
        end

        divider length: 316, color: "#31443e"

        scroll width: 316, height: 205, clip: true do
          dynamic type: :column, id: :cart_lines, spacing: 10 do
            if state.cart.empty?
              column spacing: 8, width: 300 do
                rectangle width: 42, height: 42, color: "#20312c", radius: 13 do
                  icon :plus, size: 17, color: "#69d3a7"
                end
                text "Your tray is empty", bold: true, color: "#f4fbf8"
                text "Choose a drink from the menu to get started.", width: 280,
                     style: :caption, color: "#8fa69f", wrap: true
              end
            else
              state.cart.each { |key, quantity| restaurant_cart_line(key, quantity) }
            end
          end
        end

        dynamic type: :column, id: :checkout_controls, spacing: 9 do
          button_group state.service_type, id: :service_type, options: ["Dine in", "Takeaway"],
                       width: 316, foreground: "#f4fbf8", background: "#1b2b26", accent: "#69d3a7" do |event|
            state.service_type = event.fetch("value", "Dine in")
          end

          if state.service_type == "Dine in"
            number_field state.table_number, id: :table_number, label: "Table", from: 1, to: 99, step: 1,
                         field_width: 82, foreground: "#f4fbf8", accent: "#69d3a7" do |event|
              state.table_number = event.fetch("value", 1).to_i
            end
          end

          row spacing: 7, alignment: :center do
            text "TIP", style: :caption, color: "#8fa69f", wrap: false
            [0, 10, 15, 20].each do |tip|
              chip "#{tip}%", id: "tip.#{tip}", selected: state.tip_percent == tip,
                             background: "#1b2b26", selected_background: "#f1c96a",
                             foreground: "#cbd9d4", selected_foreground: "#171207", accent: "#f1c96a" do
                state.tip_percent = tip
              end
            end
          end

          totals = restaurant_totals
          row spacing: 8 do
            text "Subtotal", style: :caption, width: 220, color: "#8fa69f"
            text restaurant_money(totals[:subtotal]), width: 88, color: "#cbd9d4", wrap: false
          end
          row spacing: 8 do
            text "Tax + tip", style: :caption, width: 220, color: "#8fa69f"
            text restaurant_money(totals[:tax] + totals[:tip]), width: 88, color: "#cbd9d4", wrap: false
          end
          row spacing: 8 do
            text "Total", bold: true, width: 220, color: "#f4fbf8"
            text restaurant_money(totals[:total]), bold: true, width: 88, color: "#69d3a7", wrap: false
          end

          button "Place order", id: :place_order, icon: :check, width: 316,
                  enabled: !state.cart.empty?, background: state.cart.empty? ? "#263631" : "#69d3a7",
                  foreground: state.cart.empty? ? "#71857e" : "#07110e",
                  accent: "#69d3a7", bordered: false, vertical_padding: 12 do
            restaurant_submit_order unless state.cart.empty?
          end
        end
      end
    end

    def restaurant_drinks_screen
      column spacing: 16 do
        restaurant_header
        restaurant_toolbar
        row spacing: 18, alignment: :start do
          restaurant_menu
          restaurant_cart
        end
      end
    end
  end
end
