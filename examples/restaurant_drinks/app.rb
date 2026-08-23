# frozen_string_literal: true

require "zui"
require_relative "components/drink_ordering"

module RestaurantDrinks
  def self.build
    Zui::Application.new(ui: UI) do
      state :query, ""
      state :category, "All"
      state :size, "Regular"
      state :cart, {}
      state :service_type, "Dine in"
      state :table_number, 12
      state :tip_percent, 15
      state :order_number, 1048
      state :last_receipt, ""
      state :confirmation_open, false
      state :bar_status, "STANDBY"
      state :bar_progress, 0

      app :main, title: "Nova Pour · Future Restaurant Drinks", width: 1240, height: 820,
                 min_width: 1120, min_height: 720, color: "#0b1512" do
        restaurant_drinks_screen

        confirmation = alert_dialog "Order confirmed", "Sent to the bar", id: :order_confirmation,
                                    severity: :success, opened: false, standard_buttons: [:ok],
                                    informative_text: "", detailed_text: "", width: 500, height: 390,
                                    centered: true, image: "assets/future-pour-bar.jpg", image_height: 140,
                                    image_fill_mode: :preserve_aspect_crop,
                                    header_background: "#10231f", footer_background: "#10231f",
                                    background: "#0b1714", foreground: "#f4fbf8", muted: "#93aaa2",
                                    accent: "#64f5bf", button_accent: "#64f5bf", border_color: "#2c6153"
        bind(confirmation, :opened) { state.confirmation_open }
        bind(confirmation, :title) { "Order ##{state.order_number} confirmed" }
        bind(confirmation, :informative_text) { state.last_receipt }
        on(confirmation, :close) { state.confirmation_open = false }
      end

      every(1.0) do
        next unless state.bar_progress.positive? && state.bar_progress < 100

        transaction do
          state.bar_progress = [state.bar_progress + 11, 100].min
          state.bar_status = state.bar_progress >= 100 ? "READY" : "MIXING"
        end
      end
    end
  end

  def self.run = build.run
end
