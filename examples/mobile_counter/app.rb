# frozen_string_literal: true

require "zui"

module MobileCounter
  module UI
    def mobile_counter
      container padding: 24 do
        column spacing: 18 do
          badge "ZUI MOBILE", size: 30, background: "#173126", foreground: "#66ffb2"
          text "Touch Counter", size: 30, bold: true, color: "#f3fff7", wrap: false
          text "A Ruby interface running inside a native iOS app.",
               width: 320, color: "#91a89d", wrap: true

          card padding: 24, width: 330, color: "#0d1b18", border_color: "#24483b" do
            column spacing: 16 do
              count = text "0 taps", size: 42, bold: true, color: "#66ffb2", wrap: false
              bind(count, :text) { "#{state.count} taps" }

              meter = progress value: 0, minimum: 0, maximum: 20, width: 282,
                               color: "#66ffb2"
              bind(meter, :value) { state.count }

              button "Tap me", width: 282, height: 64, icon: :plus,
                               background: "#66ffb2", foreground: "#07110d" do
                state.count = (state.count + 1) % 21
              end

              button "Reset", width: 282, height: 52, icon: :reset, bordered: true,
                              background: "transparent", foreground: "#b8cec3" do
                state.count = 0
              end
            end
          end

          text "Tap, swipe, and native rendering—without a web view.",
               width: 320, style: :caption, color: "#6f8a7d", wrap: true
        end
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :count, 0
      app :main, title: "Zui Mobile Counter", width: 390, height: 844,
                 min_width: 320, min_height: 568, color: "#07110d", fullscreen: true do
        mobile_counter
      end
    end
  end

  def self.run = build.run
end
