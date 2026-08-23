# frozen_string_literal: true

require "zui"

module OrbitalWeatherConsole
  INK = "#030914"
  PANEL = "#081526"
  PANEL_ALT = "#0d1c2f"
  BORDER = "#183855"
  WHITE = "#eef9ff"
  MUTED = "#7293ab"
  CYAN = "#45dcff"
  BLUE = "#5287ff"
  VIOLET = "#9d79ff"
  MINT = "#54f2b0"
  GOLD = "#ffd36d"
  RED = "#ff647d"

  module UI
    def weather_layer_brightness
      { "Visible" => 0.02, "Infrared" => -0.16, "Moisture" => -0.04 }.fetch(state.layer, 0.0)
    end

    def weather_layer_saturation
      { "Visible" => 0.08, "Infrared" => -0.68, "Moisture" => 0.36 }.fetch(state.layer, 0.0)
    end

    def weather_layer_colorization
      { "Visible" => 0.0, "Infrared" => 0.58, "Moisture" => 0.30 }.fetch(state.layer, 0.0)
    end

    def weather_layer_color
      { "Visible" => "#ffffff", "Infrared" => OrbitalWeatherConsole::VIOLET,
        "Moisture" => OrbitalWeatherConsole::CYAN }.fetch(state.layer, "#ffffff")
    end

    def weather_header
      rectangle width: 1392, height: 74, padding: 14, color: OrbitalWeatherConsole::PANEL,
                radius: 20, border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          rectangle width: 44, height: 44, radius: 14, color: "#102b3d",
                    border_color: OrbitalWeatherConsole::CYAN, border_width: 1 do
            icon :globe, size: 22, color: OrbitalWeatherConsole::CYAN
          end
          column spacing: 1, width: 380 do
            text "STRATOS / ORBITAL WEATHER", size: 19, bold: true,
                 color: OrbitalWeatherConsole::WHITE, wrap: false
            text "ATLANTIC BASIN · SYNTHETIC APERTURE ARRAY", style: :caption,
                 color: OrbitalWeatherConsole::MUTED, wrap: false
          end
          spacer width: 560
          chip "ORBIT 411", icon: :location, selected: true, background: "#112638",
                            selected_background: "#12302f", foreground: OrbitalWeatherConsole::MINT,
                            selected_foreground: OrbitalWeatherConsole::MINT, accent: OrbitalWeatherConsole::MINT
          column spacing: 1, width: 130 do
            text "NEXT PASS", style: :caption, color: OrbitalWeatherConsole::MUTED, wrap: false
            pass = text state.next_pass, id: :next_pass, bold: true,
                        color: OrbitalWeatherConsole::WHITE, wrap: false
            bind(pass, :text) { state.next_pass }
          end
          badge "CAT 3", size: 30, background: "#3a1723", foreground: OrbitalWeatherConsole::RED
        end
      end
    end

    def weather_orbit_view
      stack do
        layer_effect = multi_effect id: :weather_layer_effect, width: 856, height: 432,
                                    brightness: weather_layer_brightness,
                                    saturation: weather_layer_saturation,
                                    colorization: weather_layer_colorization,
                                    colorization_color: weather_layer_color do
          image "assets/orbital-storm.png", id: :storm_image, width: 856, height: 432,
                fill_mode: :preserve_aspect_crop, asynchronous: true, cache: true, mipmap: true
        end
        bind(layer_effect, :brightness) { weather_layer_brightness }
        bind(layer_effect, :saturation) { weather_layer_saturation }
        bind(layer_effect, :colorization) { weather_layer_colorization }
        bind(layer_effect, :colorization_color) { weather_layer_color }
        gradient colors: ["#b0030914", "#10030914", "#88030914"], stops: [0.0, 0.55, 1.0],
                 width: 856, height: 432, start_x: 0, end_x: 856, radius: 22
        particles = particle_system id: :atmosphere_particles, width: 856, height: 432,
                        running: state.scanning,
                        emit_rate: 13, life_span: 2400, maximum_emitted: 40,
                        size: 3, end_size: 1, size_variation: 2,
                        color: OrbitalWeatherConsole::CYAN, alpha: 0.28,
                        emitter_x: 460, emitter_y: 130, emitter_width: 300, emitter_height: 170,
                        velocity_angle: 30, velocity: 12, velocity_angle_variation: 80,
                        turbulence: 18, turbulence_width: 430, turbulence_height: 300
        bind(particles, :running) { state.scanning }
        bind(particles, :color) { weather_layer_color }
        rectangle width: 856, height: 432, padding: 18, color: "transparent", radius: 22,
                  border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
          column spacing: 272 do
            row spacing: 8, alignment: :center do
              chip state.layer.upcase, id: :weather_layer_badge, selected: true,
                   background: "#102a3a", selected_background: "#102a3a",
                   foreground: OrbitalWeatherConsole::CYAN,
                   selected_foreground: OrbitalWeatherConsole::CYAN,
                   accent: OrbitalWeatherConsole::CYAN
              spacer width: 425
              feed = badge "LIVE", id: :weather_feed_status, size: 24,
                           background: "#133026", foreground: OrbitalWeatherConsole::MINT
              bind(feed, :value) { state.scanning ? "LIVE" : "PAUSED" }
              bind(feed, :background) { state.scanning ? "#133026" : "#38271a" }
              scan = toggle_switch id: :weather_scan_switch, checked: state.scanning,
                                   rounded: true, track_width: 44, track_height: 24,
                                   knob_size: 18, knob_inset: 3,
                                   foreground: OrbitalWeatherConsole::WHITE,
                                   accent: OrbitalWeatherConsole::MINT do |event|
                state.scanning = event.fetch("value", false) == true
              end
              bind(scan, :checked) { state.scanning }
            end
            column spacing: 5 do
              text "HURRICANE ORPHEUS", size: 25, bold: true,
                   color: OrbitalWeatherConsole::WHITE, wrap: false
              distance = text "#{state.distance} km from Miami", id: :storm_distance,
                              color: "#c1d5e2", width: 500, wrap: false
              bind(distance, :text) { "#{state.distance} km from Miami" }
              row spacing: 8 do
                %w[Visible Infrared Moisture].each do |layer|
                  button = button layer, id: "layer.#{layer.downcase}",
                                  active: state.layer == layer, bordered: true,
                                  foreground: state.layer == layer ? OrbitalWeatherConsole::WHITE : OrbitalWeatherConsole::MUTED,
                                  background: state.layer == layer ? "#153248" : "transparent",
                                  accent: OrbitalWeatherConsole::CYAN do
                    transaction do
                      state.layer = layer
                      state.layer_changes = state.layer_changes + 1
                    end
                  end
                  bind(button, :active) { state.layer == layer }
                  bind(button, :background) { state.layer == layer ? "#153248" : "transparent" }
                end
              end
            end
          end
        end
      end
    end

    def weather_metric(label, value, id:, color:)
      rectangle width: 164, height: 92, padding: 11, color: OrbitalWeatherConsole::PANEL_ALT,
                radius: 15, border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
        column spacing: 3 do
          text label, style: :caption, color: OrbitalWeatherConsole::MUTED, wrap: false
          output = text value, id: id, size: 20, bold: true, color: color, wrap: false
          yield(output) if block_given?
        end
      end
    end

    def weather_intelligence
      column spacing: 14 do
        rectangle width: 522, height: 248, padding: 14, color: OrbitalWeatherConsole::PANEL,
                  radius: 20, border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
          column spacing: 7 do
            row spacing: 8, alignment: :center do
              text "STORM INTELLIGENCE", size: 15, bold: true, width: 340,
                   color: OrbitalWeatherConsole::WHITE, wrap: false
              badge "CONF 98%", size: 22, background: "#142d33", foreground: OrbitalWeatherConsole::CYAN,
                    font_size: 9
            end
            row spacing: 10 do
              weather_metric "WIND", "#{state.wind} kt", id: :wind_value,
                             color: OrbitalWeatherConsole::RED do |node|
                bind(node, :text) { "#{state.wind} kt" }
              end
              weather_metric "PRESSURE", "#{state.pressure} mb", id: :pressure_value,
                             color: OrbitalWeatherConsole::CYAN do |node|
                bind(node, :text) { "#{state.pressure} mb" }
              end
              weather_metric "MOVEMENT", "NW 11", id: :movement_value,
                             color: OrbitalWeatherConsole::MINT
            end
            radar_chart [92, 78, 83, 67, 88], id: :storm_radar,
                        labels: %w[WIND RAIN SURGE SHEAR EYE],
                        colors: [OrbitalWeatherConsole::CYAN, OrbitalWeatherConsole::VIOLET],
                        width: 490, height: 112, grid_color: "#24435b", levels: 4,
                        fill_opacity: 0.22, line_width: 2, point_size: 3
          end
        end

        rectangle width: 522, height: 170, padding: 14, color: OrbitalWeatherConsole::PANEL_ALT,
                  radius: 20, border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
          column spacing: 9 do
            text "PUBLIC SAFETY", size: 15, bold: true, color: OrbitalWeatherConsole::WHITE, wrap: false
            text "Storm-surge watch active for 4 coastal zones. Forecast confidence increased after the latest pass.",
                 size: 12, color: "#a8bfce", width: 490, wrap: true
            row spacing: 9 do
              button "Issue briefing", id: :issue_briefing, icon: :bell, bordered: true,
                     foreground: OrbitalWeatherConsole::WHITE, background: "#301824",
                     accent: OrbitalWeatherConsole::RED do
                state.briefing = true
              end
              button "Share track", id: :share_track, icon: :link, bordered: false,
                     foreground: OrbitalWeatherConsole::CYAN, background: "transparent",
                     accent: OrbitalWeatherConsole::CYAN do
                state.share_count = state.share_count + 1
              end
            end
          end
        end
      end
    end

    def weather_bottom
      row spacing: 14 do
        rectangle width: 856, height: 288, padding: 14, color: OrbitalWeatherConsole::PANEL,
                  radius: 20, border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
          column spacing: 8 do
            row spacing: 8, alignment: :center do
              column spacing: 1, width: 590 do
                text "72-HOUR PRESSURE TREND", size: 15, bold: true,
                     color: OrbitalWeatherConsole::WHITE, wrap: false
                text "Ensemble mean · 18 orbital passes", style: :caption,
                     color: OrbitalWeatherConsole::MUTED, wrap: false
              end
              chip "UPDATED", selected: true, background: "#112638",
                              selected_background: "#12302f", foreground: OrbitalWeatherConsole::MINT,
                              selected_foreground: OrbitalWeatherConsole::MINT, accent: OrbitalWeatherConsole::MINT
            end
            pressure = area_chart state.pressure_curve, id: :pressure_chart, width: 824, height: 178,
                                  color: OrbitalWeatherConsole::CYAN, fill_color: "#2545dcff",
                                  grid_color: "#18344b", line_width: 2, minimum: 920, maximum: 1000,
                                  show_grid: true
            bind(pressure, :values) { state.pressure_curve }
            row spacing: 24 do
              [["LANDFALL", "31h ± 4", OrbitalWeatherConsole::RED],
               ["SURGE", "2.8–3.4m", OrbitalWeatherConsole::GOLD],
               ["RAIN", "280mm", OrbitalWeatherConsole::CYAN],
               ["CONFIDENCE", "High", OrbitalWeatherConsole::MINT]].each do |label, value, color|
                column spacing: 1, width: 180 do
                  text label, style: :caption, color: OrbitalWeatherConsole::MUTED, wrap: false
                  text value, bold: true, color: color, wrap: false
                end
              end
            end
          end
        end
        rectangle width: 522, height: 288, padding: 14, color: OrbitalWeatherConsole::PANEL,
                  radius: 20, border_color: OrbitalWeatherConsole::BORDER, border_width: 1 do
          column spacing: 9 do
            text "REGIONAL IMPACT MATRIX", size: 15, bold: true,
                 color: OrbitalWeatherConsole::WHITE, wrap: false
            heatmap [[64, 72, 89, 95, 82], [42, 58, 76, 88, 71], [28, 46, 65, 79, 63],
                     [18, 32, 54, 66, 50]], id: :impact_heatmap,
                    x_labels: ["NOW", "+6", "+12", "+18", "+24"],
                    y_labels: %w[MIAMI KEYS NAPLES TAMPA],
                    colors: ["#122638", "#2e5c76", OrbitalWeatherConsole::GOLD, OrbitalWeatherConsole::RED],
                    width: 490, height: 220, minimum: 0, maximum: 100,
                    cell_spacing: 4, show_values: true, value_color: OrbitalWeatherConsole::WHITE
          end
        end
      end
    end

    def orbital_weather_screen
      column spacing: 14 do
        weather_header
        row spacing: 14, alignment: :start do
          weather_orbit_view
          weather_intelligence
        end
        weather_bottom
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :tick, 0
      state :layer, "Infrared"
      state :distance, 612
      state :wind, 108
      state :pressure, 947
      state :next_pass, "08:42"
      state :briefing, false
      state :scanning, true
      state :layer_changes, 0
      state :share_count, 0
      state :pressure_curve, [988, 984, 981, 976, 972, 968, 962, 957, 953, 949, 947]

      app :main, title: "Stratos · Orbital Weather", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        orbital_weather_screen
        briefing = alert_dialog "Public briefing prepared", "Coastal teams have the latest track",
                                 id: :briefing_dialog, severity: :warning, opened: false,
                                 centered: true, standard_buttons: [:ok], width: 510, height: 460,
                                 image: "assets/orbital-storm.png", image_height: 190,
                                 image_fill_mode: :preserve_aspect_crop,
                                 informative_text: "Four surge zones and two evacuation corridors are included.",
                                 background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                                 foreground: WHITE, muted: MUTED, accent: GOLD, warning_color: GOLD,
                                 button_accent: GOLD, border_color: BORDER
        bind(briefing, :opened) { state.briefing }
        on(briefing, :accept) { state.briefing = false }
        on(briefing, :close) { state.briefing = false }
      end

      every(1.0) do
        next unless state.scanning

        next_tick = state.tick + 1
        transaction do
          state.tick = next_tick
          state.distance = [580, state.distance - 1].max
          state.wind = 106 + (next_tick % 6)
          state.pressure = 945 + (next_tick % 4)
          state.next_pass = format("08:%02d", 42 - (next_tick % 30))
          state.pressure_curve = state.pressure_curve.drop(1) + [state.pressure]
        end
      end
    end
  end

  def self.run = build.run
end
