# frozen_string_literal: true

require "zui"

module SmartHomeEnergy
  INK = "#040a0d"
  PANEL = "#09151a"
  PANEL_ALT = "#0d1d23"
  BORDER = "#193b42"
  WHITE = "#effffb"
  MUTED = "#76949a"
  MINT = "#4be3c5"
  LIME = "#b8f56a"
  GOLD = "#ffd166"
  CYAN = "#55dff5"
  RED = "#ff6878"

  module UI
    def activate_home_scene(scene)
      level, lights = case scene
                      when "Morning" then [68, true]
                      when "Focus" then [88, true]
                      when "Night" then [24, true]
                      else [0, false]
                      end
      transaction do
        state.scene = scene
        state.light_level = level
        state.living_lights = lights
      end
    end

    def room_brightness
      state.living_lights ? (-0.12 + state.light_level.to_f / 220.0) : -0.78
    end

    def section_button(label, icon_name, index)
      control = button label, id: "section.#{label.downcase}", icon: icon_name,
                              width: 77, height: 50, font_size: 10, icon_size: 14,
                              active: state.section == index, bordered: true,
                              foreground: SmartHomeEnergy::WHITE, background: "#071015",
                              accent: SmartHomeEnergy::MINT do
        state.section = index
      end
      bind(control, :active) { state.section == index }
    end

    def home_header
      rectangle width: 348, height: 204, padding: 11, color: SmartHomeEnergy::PANEL,
                radius: 20, border_color: SmartHomeEnergy::BORDER, border_width: 1 do
        column spacing: 10 do
          row spacing: 8, alignment: :center do
            rectangle width: 44, height: 44, radius: 14, color: "#102821",
                      border_color: SmartHomeEnergy::MINT, border_width: 1 do
              icon :house, size: 21, color: SmartHomeEnergy::MINT
            end
            column spacing: 1, width: 164 do
              text "HABITAT ONE", size: 18, bold: true, color: SmartHomeEnergy::WHITE, wrap: false
              text "AUTONOMOUS HOME", style: :caption, color: SmartHomeEnergy::MUTED, wrap: false
            end
            secure = button state.secure ? "Secure" : "Open", id: :security_toggle,
                            width: 102, height: 48, icon: state.secure ? :lock : :unlock,
                            bordered: true, font_size: 11,
                            foreground: state.secure ? SmartHomeEnergy::MINT : SmartHomeEnergy::RED,
                            background: "transparent", accent: SmartHomeEnergy::MINT do
              state.secure = !state.secure
            end
            bind(secure, :text) { state.secure ? "Secure" : "Open" }
            bind(secure, :icon) { state.secure ? "lock" : "unlock" }
            bind(secure, :foreground) { state.secure ? SmartHomeEnergy::MINT : SmartHomeEnergy::RED }
          end
          row spacing: 14, alignment: :center do
            chip "NET POSITIVE", icon: :power, selected: true, height: 34,
                                 background: "#10281d", selected_background: "#10281d",
                                 foreground: SmartHomeEnergy::LIME,
                                 selected_foreground: SmartHomeEnergy::LIME, accent: SmartHomeEnergy::LIME
            column spacing: 1, width: 122 do
              text "OUTDOOR", style: :caption, color: SmartHomeEnergy::MUTED, wrap: false
              text "18°C · Clear", bold: true, color: SmartHomeEnergy::WHITE, wrap: false
            end
          end
          row spacing: 5 do
            section_button "Home", :house, 0
            section_button "Room", :gear, 1
            section_button "Energy", :power, 2
            section_button "Comfort", :heart, 4
          end
        end
      end
    end

    def home_twin
      rectangle width: 348, height: 488, padding: 14, color: SmartHomeEnergy::PANEL_ALT,
                radius: 20, border_color: SmartHomeEnergy::BORDER, border_width: 1 do
        column spacing: 10 do
          stack do
            room_effect = multi_effect id: :room_lighting_effect, width: 320, height: 230,
                                       brightness: room_brightness,
                                       contrast: state.living_lights ? 0.06 : 0.18,
                                       saturation: state.living_lights ? 0.08 : -0.72 do
              image "assets/smart-living-room.png", id: :room_image, width: 320, height: 230,
                    fill_mode: :preserve_aspect_crop, asynchronous: true,
                    cache: true, smooth: true, mipmap: true
            end
            bind(room_effect, :brightness) { room_brightness }
            bind(room_effect, :contrast) { state.living_lights ? 0.06 : 0.18 }
            bind(room_effect, :saturation) { state.living_lights ? 0.08 : -0.72 }
            blackout = rectangle id: :room_blackout, width: 320, height: 230,
                                 color: state.living_lights ? "#1803090d" : "#a802070a", radius: 16
            bind(blackout, :color) { state.living_lights ? "#1803090d" : "#a802070a" }
            rectangle width: 320, height: 230, padding: 12, color: "transparent", radius: 16,
                      border_color: SmartHomeEnergy::BORDER, border_width: 1 do
              column spacing: 132 do
                row spacing: 8, alignment: :center do
                  chip "LIVING ROOM", id: :scene_badge, icon: :house, selected: true, height: 34,
                       background: "#112b25", selected_background: "#112b25",
                       foreground: SmartHomeEnergy::MINT, selected_foreground: SmartHomeEnergy::MINT,
                       accent: SmartHomeEnergy::MINT
                  spacer width: 76
                  room_light = toggle_switch id: :room_light_switch, checked: state.living_lights,
                                             rounded: true, track_width: 52, track_height: 30,
                                             knob_size: 24, knob_inset: 3,
                                             foreground: SmartHomeEnergy::WHITE,
                                             accent: SmartHomeEnergy::GOLD do |event|
                    state.living_lights = event.fetch("value", false) == true
                  end
                  bind(room_light, :checked) { state.living_lights }
                end
                row spacing: 8, alignment: :center do
                  room_status = badge "LIGHTS ON", id: :room_light_status, size: 28,
                                      background: "#493717", foreground: SmartHomeEnergy::GOLD
                  bind(room_status, :value) { state.living_lights ? "LIGHTS ON" : "LIGHTS OFF" }
                  bind(room_status, :background) { state.living_lights ? "#493717" : "#17242a" }
                  spacer width: 80
                  text "ENERGY TWIN", style: :caption, bold: true,
                       color: SmartHomeEnergy::WHITE, wrap: false
                end
              end
            end
          end
          text "HOME SCENES", style: :caption, bold: true, color: SmartHomeEnergy::MUTED, wrap: false
          row spacing: 6 do
            %w[Morning Focus Away Night].each do |scene|
              control = button scene, id: "scene.#{scene.downcase}", width: 75, height: 48,
                               font_size: 10, active: state.scene == scene, bordered: true,
                               foreground: state.scene == scene ? SmartHomeEnergy::WHITE : SmartHomeEnergy::MUTED,
                               background: state.scene == scene ? "#15342a" : "#071015",
                               accent: SmartHomeEnergy::MINT do
                activate_home_scene(scene)
              end
              bind(control, :active) { state.scene == scene }
              bind(control, :background) { state.scene == scene ? "#15342a" : "#071015" }
            end
          end
          rectangle width: 320, height: 104, padding: 10, color: "#de071015",
                    radius: 14, border_color: "#4052675f", border_width: 1 do
            column spacing: 10 do
              row spacing: 8, alignment: :center do
                scene_name = text "FOCUS SCENE", id: :active_room_scene, style: :caption,
                                  bold: true, width: 156, color: SmartHomeEnergy::MINT, wrap: false
                bind(scene_name, :text) { "#{state.scene.upcase} SCENE" }
                power = text "Lighting 46 W", id: :room_light_usage, style: :caption,
                             width: 92, color: SmartHomeEnergy::MUTED, wrap: false
                bind(power, :text) { "#{state.living_lights ? "46 W" : "0 W"}" }
                level = text "88%", id: :room_light_level, bold: true,
                             color: SmartHomeEnergy::GOLD, wrap: false
                bind(level, :text) { "#{state.light_level.round}%" }
              end
              dimmer = slider state.light_level, id: :room_brightness_slider,
                              minimum: 0, maximum: 100, step: 1, width: 298, height: 42,
                              track_color: "#26343a", fill_color: SmartHomeEnergy::GOLD,
                              knob_color: SmartHomeEnergy::WHITE,
                              track_height: 8, knob_size: 24 do |event|
                value = event.fetch("value", state.light_level).to_f
                transaction do
                  state.light_level = value
                  state.living_lights = value > 0
                end
              end
              bind(dimmer, :value) { state.light_level }
            end
          end
        end
      end
    end

    def energy_flow
      rectangle width: 348, height: 476, padding: 14, color: SmartHomeEnergy::PANEL,
                radius: 20, border_color: SmartHomeEnergy::BORDER, border_width: 1 do
        column spacing: 9 do
          row spacing: 8, alignment: :center do
            text "LIVE ENERGY FLOW", size: 15, bold: true, width: 210,
                 color: SmartHomeEnergy::WHITE, wrap: false
            badge "+2.8 kW", size: 24, background: "#153427", foreground: SmartHomeEnergy::LIME
          end
          row spacing: 10, alignment: :center do
            solar = radial_gauge [], id: :solar_gauge, value: state.solar,
                                  minimum: 0, maximum: 10, width: 100, height: 116,
                                  color: SmartHomeEnergy::GOLD, track_color: "#342c18", thickness: 9,
                                  font_size: 11, label: "Solar", label_format: "%{value} kW"
            bind(solar, :value) { state.solar }
            battery = radial_gauge [], id: :home_battery_gauge, value: state.battery,
                                    minimum: 0, maximum: 100, width: 100, height: 116,
                                    color: SmartHomeEnergy::MINT, track_color: "#18352e", thickness: 9,
                                    font_size: 11, label: "Battery", label_format: "%{value}%"
            bind(battery, :value) { state.battery }
            usage = radial_gauge [], id: :usage_gauge, value: state.usage,
                                  minimum: 0, maximum: 8, width: 100, height: 116,
                                  color: SmartHomeEnergy::CYAN, track_color: "#18313a", thickness: 9,
                                  font_size: 11, label: "Home", label_format: "%{value} kW"
            bind(usage, :value) { state.usage }
          end
          divider length: 320, color: SmartHomeEnergy::BORDER
          text "ROOM AUTOMATION", style: :caption, bold: true,
               color: SmartHomeEnergy::MUTED, wrap: false
          [["Living lights", :living_lights, SmartHomeEnergy::GOLD],
           ["Climate intelligence", :climate, SmartHomeEnergy::CYAN],
           ["Studio equipment", :studio, SmartHomeEnergy::MINT]].each do |label, state_name, color|
            row spacing: 10, alignment: :center do
              column spacing: 1, width: 258 do
                text label, bold: true, color: SmartHomeEnergy::WHITE, wrap: false
                status = text state.public_send(state_name) ? "Active" : "Standby",
                              id: "#{state_name}.status", style: :caption, color: color, wrap: false
                bind(status, :text) { state.public_send(state_name) ? "Active" : "Standby" }
              end
              control = toggle_switch id: "#{state_name}.switch", checked: state.public_send(state_name),
                                      rounded: true, cursor_ring: false, track_width: 52,
                                      track_height: 30, knob_size: 24, knob_inset: 3,
                                      foreground: SmartHomeEnergy::WHITE, accent: color do |event|
                state.public_send("#{state_name}=", event.fetch("value", false) == true)
              end
              bind(control, :checked) { state.public_send(state_name) }
            end
          end
          row spacing: 10 do
            button "Optimize", id: :optimize_energy, icon: :power, width: 155, height: 52,
                   bordered: true, foreground: SmartHomeEnergy::INK,
                   background: SmartHomeEnergy::MINT, accent: SmartHomeEnergy::MINT do
              transaction do
                state.usage = 3.2
                state.optimized = true
              end
            end
            button "Report", id: :energy_report, icon: :file, width: 155, height: 52,
                   bordered: true, foreground: SmartHomeEnergy::WHITE, background: "transparent",
                   accent: SmartHomeEnergy::CYAN do
              state.report_dialog = true
            end
          end
        end
      end
    end

    def energy_mix
      rectangle width: 348, height: 310, padding: 14, color: SmartHomeEnergy::PANEL,
                radius: 20, border_color: SmartHomeEnergy::BORDER, border_width: 1 do
        column spacing: 8 do
          row spacing: 8, alignment: :center do
            text "24-HOUR ENERGY MIX", size: 15, bold: true, width: 190,
                 color: SmartHomeEnergy::WHITE, wrap: false
            chip "FORECAST", selected: true, height: 34, background: "#112b25",
                             selected_background: "#112b25", foreground: SmartHomeEnergy::MINT,
                             selected_foreground: SmartHomeEnergy::MINT, accent: SmartHomeEnergy::MINT
          end
          stacked_bar_chart [], id: :energy_mix_chart,
                            series: [[0.2, 0.2, 0.3, 0.6, 1.8, 4.2, 6.8, 8.1, 6.4, 3.1, 1.0, 0.3],
                                     [1.4, 1.2, 1.1, 1.0, 0.8, 0.3, 0.2, 0.0, 0.2, 0.6, 1.1, 1.5],
                                     [2.2, 2.0, 1.8, 1.7, 2.1, 2.8, 3.6, 4.1, 4.6, 4.0, 3.2, 2.6]],
                            labels: %w[00 02 04 06 08 10 12 14 16 18 20 22],
                            colors: [SmartHomeEnergy::GOLD, SmartHomeEnergy::MINT, SmartHomeEnergy::CYAN],
                            width: 320, height: 230, grid_color: "#1b3840",
                            minimum: 0, maximum: 12, show_grid: true,
                            bar_spacing: 3, stack_spacing: 1, legend: false
        end
      end
    end

    def comfort_matrix
      rectangle width: 348, height: 296, padding: 14, color: SmartHomeEnergy::PANEL_ALT,
                radius: 20, border_color: SmartHomeEnergy::BORDER, border_width: 1 do
        column spacing: 9 do
          text "COMFORT MATRIX", size: 15, bold: true, color: SmartHomeEnergy::WHITE, wrap: false
          heatmap [[22, 21, 20, 21, 22, 23], [21, 21, 21, 22, 22, 22],
                   [20, 20, 21, 21, 22, 21], [22, 23, 23, 22, 22, 21]],
                  id: :comfort_heatmap, x_labels: %w[06 09 12 15 18 21],
                  y_labels: %w[LIVE KITCH STUDIO SLEEP],
                  colors: ["#17313a", SmartHomeEnergy::CYAN, SmartHomeEnergy::MINT, SmartHomeEnergy::GOLD],
                  width: 320, height: 196, minimum: 18, maximum: 25, font_size: 10,
                  cell_spacing: 4, show_values: true, value_color: SmartHomeEnergy::WHITE
          row spacing: 13 do
            text "AIR 98%", size: 11, bold: true, color: SmartHomeEnergy::MINT, wrap: false
            text "HUMID 44%", size: 11, bold: true, color: SmartHomeEnergy::CYAN, wrap: false
            text "QUIET 31 dB", size: 11, bold: true, color: SmartHomeEnergy::WHITE, wrap: false
          end
        end
      end
    end

    def smart_home_screen
      view = responsive_view id: :home_feed, card_width: 348, spacing: 12, padding: 12,
                             max_columns: 4, scroll_index: state.section,
                             background: SmartHomeEnergy::INK do
        home_header
        home_twin
        energy_flow
        energy_mix
        comfort_matrix
      end
      bind(view, :scroll_index) { state.section }
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :tick, 0
      state :scene, "Focus"
      state :secure, true
      state :solar, 7.8
      state :battery, 84
      state :usage, 4.6
      state :living_lights, true
      state :light_level, 88
      state :climate, true
      state :studio, false
      state :optimized, false
      state :report_dialog, false
      state :section, 0

      app :main, title: "Habitat One · Smart Energy Twin", width: 1180, height: 860,
                 min_width: 320, min_height: 568, color: INK do
        smart_home_screen
        report = alert_dialog "Energy report ready", "Habitat exported 18.4 kWh today",
                              id: :energy_report_dialog, severity: :success, opened: false,
                              centered: true, standard_buttons: [:ok], width: 348, height: 370,
                              informative_text: "Solar covered 78% of demand and the battery avoided the evening peak.",
                              background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                              foreground: WHITE, muted: MUTED, accent: MINT,
                              button_accent: MINT, border_color: BORDER
        bind(report, :opened) { state.report_dialog }
        on(report, :accept) { state.report_dialog = false }
        on(report, :close) { state.report_dialog = false }
      end

      every(1.0) do
        next_tick = state.tick + 1
        transaction do
          state.tick = next_tick
          state.solar = 7.2 + (next_tick % 8) / 10.0
          state.battery = 82 + (next_tick % 5)
          lighting_load = state.living_lights ? state.light_level.to_f / 1000.0 : 0.0
          state.usage = ((state.optimized ? 3.0 + (next_tick % 4) / 10.0 : 4.2 + (next_tick % 6) / 10.0) + lighting_load).round(1)
        end
      end
    end
  end

  def self.run = build.run
end
