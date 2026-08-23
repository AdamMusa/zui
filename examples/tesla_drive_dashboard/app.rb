# frozen_string_literal: true

require "zui"

module TeslaDriveDashboard
  INK = "#050608"
  PANEL = "#0d1118"
  PANEL_ALT = "#131923"
  LINE = "#27303c"
  WHITE = "#f5f7fa"
  MUTED = "#8c96a5"
  RED = "#ff4d5f"
  CYAN = "#55dff5"
  MINT = "#67f0b5"
  LIME = "#c9ff18"
  VEHICLE_VIEWS = %w[
    assets/electric-grand-tourer.png
    assets/vehicle-front.png
    assets/vehicle-side.png
  ].freeze

  module UI
    def vehicle_image_source
      return "assets/vehicle-trunk-open.png" if state.trunk_open
      return "assets/vehicle-charge-open.png" if state.charge_port_open

      TeslaDriveDashboard::VEHICLE_VIEWS[state.vehicle_view % TeslaDriveDashboard::VEHICLE_VIEWS.length]
    end

    def select_vehicle_view(offset)
      transaction do
        state.trunk_open = false
        state.charge_port_open = false
        state.vehicle_view = (state.vehicle_view + offset) % TeslaDriveDashboard::VEHICLE_VIEWS.length
        state.camera_angle = (state.vehicle_view - 1) * 45
      end
    end

    def toggle_vehicle_panel(panel)
      opening = !state[panel]
      transaction do
        state.driving = false if opening
        state.speed = 0 if opening
        state.locked = false if opening
        state.trunk_open = false
        state.charge_port_open = false
        state[panel] = opening
      end
    end

    def drive_metric(label, value, id: nil, color: TeslaDriveDashboard::WHITE, width: 126, &reader)
      column spacing: 2, width: width do
        text label, style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
        metric = text value, id: id, size: 16, bold: true, color: color, wrap: false
        bind(metric, :text, &reader) if reader
      end
    end

    def drive_map_commands
      marker_y = 220 - state.route_progress.to_f * 1.15
      [
        { op: "fill_rect", x: 0, y: 0, width: 414, height: 278, fill_style: "#171918" },
        { op: "begin_path", stroke_style: "#29302d", line_width: 7, line_cap: "round" },
        { op: "move_to", x: 0, y: 58 }, { op: "bezier_curve_to", cp1x: 102, cp1y: 18, cp2x: 220, cp2y: 106, x: 414, y: 66 }, { op: "stroke" },
        { op: "begin_path", stroke_style: "#252c29", line_width: 6, line_cap: "round" },
        { op: "move_to", x: 0, y: 238 }, { op: "bezier_curve_to", cp1x: 128, cp1y: 190, cp2x: 278, cp2y: 270, x: 414, y: 226 }, { op: "stroke" },
        { op: "begin_path", stroke_style: "#2d3531", line_width: 4, line_cap: "round" },
        { op: "move_to", x: 66, y: 0 }, { op: "bezier_curve_to", cp1x: 104, cp1y: 80, cp2x: 72, cp2y: 178, x: 148, y: 278 }, { op: "stroke" },
        { op: "begin_path", stroke_style: "#2d3531", line_width: 4, line_cap: "round" },
        { op: "move_to", x: 342, y: 0 }, { op: "bezier_curve_to", cp1x: 306, cp1y: 82, cp2x: 382, cp2y: 182, x: 318, y: 278 }, { op: "stroke" },
        { op: "begin_path", stroke_style: TeslaDriveDashboard::LIME, line_width: 7, line_cap: "round", line_join: "round" },
        { op: "move_to", x: 206, y: 268 }, { op: "line_to", x: 216, y: 226 },
        { op: "line_to", x: 174, y: 182 }, { op: "line_to", x: 220, y: 138 },
        { op: "line_to", x: 208, y: 86 }, { op: "line_to", x: 278, y: 20 }, { op: "stroke" },
        { op: "begin_path", fill_style: TeslaDriveDashboard::LIME, stroke_style: "#0b0c0c", line_width: 4 },
        { op: "arc", x: 206, y: marker_y, radius: 10 }, { op: "fill" }, { op: "stroke" },
        { op: "fill_text", text: "Snowline Pass", x: 250, y: 120, fill_style: "#d6ddd8", font: "12px sans-serif" },
        { op: "fill_text", text: "Supercharger · 18 stalls", x: 220, y: 258, fill_style: "#7f8984", font: "11px sans-serif" },
        { op: "fill_text", text: "A-12", x: 88, y: 74, fill_style: "#919a95", font: "bold 11px sans-serif" }
      ]
    end

    def drive_header
      rectangle width: 1392, height: 72, padding: 14, color: "#0c0d0e",
                radius: 20, border_color: "#2a2d2d", border_width: 1 do
        row spacing: 14, alignment: :center do
          rectangle width: 42, height: 42, radius: 21, color: "#202322" do
            text "T", size: 20, bold: true, color: TeslaDriveDashboard::LIME, wrap: false
          end
          column spacing: 1, width: 210 do
            text "DASHBOARD", size: 18, bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
            text "ELECTRIC COCKPIT · LIVE", style: :caption,
                 color: TeslaDriveDashboard::MUTED, wrap: false
          end
          search = search_field state.destination_search, id: :destination_search, width: 490,
                                suggestions: ["Snowline Pass", "Nearest Supercharger", "Home"],
                                foreground: TeslaDriveDashboard::WHITE, background: "#1d201f",
                                accent: TeslaDriveDashboard::LIME do |event|
            state.destination_search = event.fetch("value", "").to_s
          end
          bind(search, :text) { state.destination_search }
          spacer width: 180
          column spacing: 0, width: 82 do
            text "23°C", size: 17, bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
            text "Cloudy", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
          end
          text "10:45", bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
          lock = button(state.locked ? "Locked" : "Unlocked", id: :vehicle_lock,
                        icon: state.locked ? :lock : :unlock, bordered: true,
                        foreground: state.locked ? TeslaDriveDashboard::LIME : TeslaDriveDashboard::RED,
                        background: "#1a1d1c", accent: TeslaDriveDashboard::LIME) do
            state.locked = !state.locked
          end
          bind(lock, :text) { state.locked ? "Locked" : "Unlocked" }
          bind(lock, :icon) { state.locked ? "lock" : "unlock" }
          bind(lock, :foreground) { state.locked ? TeslaDriveDashboard::LIME : TeslaDriveDashboard::RED }
        end
      end
    end

    def drive_hero
      rectangle width: 932, height: 540, color: "#e8ece8", radius: 22,
                border_color: "#384354", border_width: 1 do
        row spacing: 0, alignment: :start do
          rectangle width: 350, height: 540, color: "#f4f5f3" do
            column spacing: 10 do
              row spacing: 12, alignment: :center do
                column spacing: 0, width: 174 do
                  speed = text state.speed.to_i, id: :vehicle_speed, size: 56, bold: true,
                               color: "#171b1f", wrap: false
                  bind(speed, :text) { state.speed.to_i.to_s }
                  text "MPH", style: :caption, bold: true, color: "#6d7479", wrap: false
                end
                gear = badge state.driving ? "D" : "P", id: :drive_gear, size: 36,
                             background: "#20252b", foreground: "#ffffff", font_size: 15
                bind(gear, :value) { state.driving ? "D" : "P" }
                rectangle width: 58, height: 58, radius: 29, color: "#ffffff",
                          border_color: "#d8dcdd", border_width: 3 do
                  text "65", size: 20, bold: true, color: "#20252b", wrap: false
                end
              end

              hero_image = image "assets/vehicle-status-render.png", id: :vehicle_hero_image,
                                 width: 350, height: 275, fill_mode: :preserve_aspect_fit,
                                 asynchronous: true, cache: true, mipmap: true
              on(hero_image, :loaded) { state.image_ready = true }

              row spacing: 6, alignment: :center do
                charge = button "Charge", id: :charge_port_toggle, icon: :power,
                                bordered: true, foreground: "#30363b", background: "#ffffff",
                                accent: TeslaDriveDashboard::RED do
                  state.charge_port_open = !state.charge_port_open
                end
                trunk = button "Trunk", id: :trunk_toggle, icon: :upload,
                               bordered: true, foreground: "#30363b", background: "#ffffff",
                               accent: TeslaDriveDashboard::CYAN do
                  state.trunk_open = !state.trunk_open
                end
                lock = button state.locked ? "Locked" : "Unlocked", id: :hero_vehicle_lock,
                              icon: state.locked ? :lock : :unlock, bordered: true,
                              foreground: "#30363b", background: "#ffffff",
                              accent: TeslaDriveDashboard::RED do
                  state.locked = !state.locked
                end
                bind(lock, :text) { state.locked ? "Locked" : "Unlocked" }
                bind(lock, :icon) { state.locked ? "lock" : "unlock" }
              end

              row spacing: 9, alignment: :center do
                autopilot = toggle_switch id: :autopilot_switch, checked: state.autopilot,
                                          rounded: true, track_width: 44, track_height: 24,
                                          knob_size: 18, knob_inset: 3, foreground: "#ffffff",
                                          accent: "#3b82f6" do |event|
                  state.autopilot = event.fetch("value", false) == true
                end
                bind(autopilot, :checked) { state.autopilot }
                pilot = text state.autopilot ? "Autosteer active" : "Autosteer available",
                             id: :autopilot_status, bold: true, color: "#30363b",
                             width: 150, wrap: false
                bind(pilot, :text) { state.autopilot ? "Autosteer active" : "Autosteer available" }
                drive = button state.driving ? "Pause" : "Drive", id: :drive_toggle,
                               icon: state.driving ? :pause : :play, active: state.driving,
                               bordered: true, foreground: "#ffffff", background: "#20252b",
                               accent: "#3b82f6" do
                  state.driving = !state.driving
                end
                bind(drive, :text) { state.driving ? "Pause" : "Drive" }
                bind(drive, :icon) { state.driving ? "pause" : "play" }
                bind(drive, :active) { state.driving }
              end
            end
          end

          stack width: 582, height: 540 do
            map = canvas drive_map_commands, id: :route_map, width: 582, height: 540,
                         background: "#e8ece8", antialiasing: true, smooth: true
            bind(map, :commands) { drive_map_commands }

            rectangle width: 582, height: 540, padding: 16, color: "transparent" do
              column spacing: 330 do
                rectangle width: 550, height: 94, padding: 12, color: "#f4ffffff",
                          radius: 14, border_color: "#d5dcda", border_width: 1 do
                  row spacing: 12, alignment: :center do
                    rectangle width: 42, height: 42, radius: 12, color: "#3b82f6" do
                      icon :arrow_up, size: 18, color: "#ffffff"
                    end
                    column spacing: 1, width: 384 do
                      text "Continue on A-12", size: 17, bold: true,
                           color: "#20252b", wrap: false
                      remaining = text "#{state.route_miles.round(1)} mi · Snowline Pass",
                                       id: :route_remaining, style: :caption,
                                       color: "#67716f", wrap: false
                      bind(remaining, :text) { "#{state.route_miles.round(1)} mi · Snowline Pass" }
                    end
                    button "End", id: :end_route, bordered: false, foreground: "#b23a48",
                           background: "transparent", accent: "#b23a48" do
                      state.driving = false
                    end
                  end
                end

                rectangle width: 550, height: 64, padding: 9, color: "#f4ffffff",
                          radius: 16, border_color: "#d5dcda", border_width: 1 do
                  row spacing: 8, alignment: :center do
                    round_button "", id: :temperature_down, icon: :minus, diameter: 34,
                                 foreground: "#30363b", background: "#eef1ef", accent: "#3b82f6" do
                      state.cabin_temperature = [state.cabin_temperature - 0.5, 16.0].max
                    end
                    cabin = text "#{state.cabin_temperature}°", id: :cabin_temperature,
                                 size: 16, bold: true, color: "#20252b", wrap: false
                    bind(cabin, :text) { format("%.1f°", state.cabin_temperature) }
                    round_button "", id: :temperature_up, icon: :plus, diameter: 34,
                                 foreground: "#30363b", background: "#eef1ef", accent: "#3b82f6" do
                      state.cabin_temperature = [state.cabin_temperature + 0.5, 28.0].min
                    end
                    spacer width: 168
                    seat = button "Seat #{state.seat_heat}", id: :seat_heat, icon: :user,
                                  bordered: false, foreground: "#30363b",
                                  background: "transparent", accent: TeslaDriveDashboard::RED do
                      state.seat_heat = (state.seat_heat + 1) % 4
                    end
                    bind(seat, :text) { "Seat #{state.seat_heat}" }
                    media = round_button "", id: :media_toggle,
                                         icon: state.media_playing ? :pause : :play, diameter: 38,
                                         foreground: "#ffffff", background: "#20252b",
                                         accent: "#3b82f6" do
                      state.media_playing = !state.media_playing
                    end
                    bind(media, :icon) { state.media_playing ? "pause" : "play" }
                    text "21:42", bold: true, color: "#30363b", wrap: false
                  end
                end
              end
            end
          end
        end
      end
    end

    def drive_side_panel
      column spacing: 14 do
        rectangle width: 446, height: 262, padding: 16, color: TeslaDriveDashboard::PANEL,
                  radius: 20, border_color: TeslaDriveDashboard::LINE, border_width: 1 do
          column spacing: 10 do
            row spacing: 8, alignment: :center do
              text "ENERGY", size: 15, bold: true, width: 310,
                   color: TeslaDriveDashboard::WHITE, wrap: false
              badge "#{state.charge}%", id: :charge_badge, size: 26,
                    background: "#173126", foreground: TeslaDriveDashboard::MINT
            end
            row spacing: 24, alignment: :center do
              battery = radial_gauge [], id: :battery_gauge, value: state.charge,
                                     minimum: 0, maximum: 100, width: 172, height: 172,
                                     color: TeslaDriveDashboard::MINT, track_color: "#1c2b2a",
                                     thickness: 12, label: "Battery", label_format: "%{value}%"
              bind(battery, :value) { state.charge }
              column spacing: 14, width: 190 do
                drive_metric "EST. RANGE", "#{state.range} mi", id: :energy_range,
                             color: TeslaDriveDashboard::CYAN, width: 180 do
                  "#{state.range.round(1)} mi"
                end
                drive_metric "AVG. CONSUMPTION", "238 Wh/mi", width: 180
                charge = button "Plan charge", id: :plan_charge, icon: :location,
                                bordered: true, foreground: TeslaDriveDashboard::WHITE,
                                background: "#121923", accent: TeslaDriveDashboard::CYAN do
                  state.charge_dialog = true
                end
              end
            end
          end
        end

        rectangle width: 446, height: 264, padding: 16, color: TeslaDriveDashboard::PANEL,
                  radius: 20, border_color: TeslaDriveDashboard::LINE, border_width: 1 do
          column spacing: 13 do
            text "DRIVE DYNAMICS", size: 15, bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
            row spacing: 8 do
              %w[Chill Standard Sport].each do |mode|
                mode_button = button mode, id: "mode.#{mode.downcase}",
                                     active: state.mode == mode, bordered: true,
                                     foreground: state.mode == mode ? TeslaDriveDashboard::WHITE : TeslaDriveDashboard::MUTED,
                                     background: state.mode == mode ? "#36171e" : "transparent",
                                     accent: TeslaDriveDashboard::RED do
                  state.mode = mode
                end
                bind(mode_button, :active) { state.mode == mode }
                bind(mode_button, :background) { state.mode == mode ? "#36171e" : "transparent" }
                bind(mode_button, :foreground) do
                  state.mode == mode ? TeslaDriveDashboard::WHITE : TeslaDriveDashboard::MUTED
                end
              end
            end
            divider length: 410, color: TeslaDriveDashboard::LINE
            row spacing: 12, alignment: :center do
              column spacing: 1, width: 330 do
                text "CABIN CLIMATE", bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
                climate = text state.climate ? "21°C · Auto" : "Climate sleeping", id: :climate_status,
                               style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
                bind(climate, :text) { state.climate ? "21°C · Auto" : "Climate sleeping" }
              end
              switch = toggle_switch id: :climate_switch, checked: state.climate,
                                     rounded: true, cursor_ring: false, track_width: 44,
                                     track_height: 24, knob_size: 18, knob_inset: 3,
                                     foreground: TeslaDriveDashboard::WHITE,
                                     accent: TeslaDriveDashboard::RED do |event|
                state.climate = event.fetch("value", false) == true
              end
              bind(switch, :checked) { state.climate }
            end
            text "TRACTION DISTRIBUTION", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
            traction = progress state.traction, id: :traction_progress, minimum: 0, maximum: 100,
                                width: 408, height: 8, color: TeslaDriveDashboard::RED
            bind(traction, :value) { state.traction }
          end
        end
      end
    end

    def drive_bottom
      row spacing: 14 do
        rectangle width: 932, height: 152, padding: 14, color: TeslaDriveDashboard::PANEL,
                  radius: 20, border_color: TeslaDriveDashboard::LINE, border_width: 1 do
          column spacing: 7 do
            row spacing: 8, alignment: :center do
              text "POWER DELIVERY", size: 15, bold: true, width: 670,
                   color: TeslaDriveDashboard::WHITE, wrap: false
              chip "LIVE", selected: true, background: "#14221d", selected_background: "#14221d",
                           foreground: TeslaDriveDashboard::MINT,
                           selected_foreground: TeslaDriveDashboard::MINT, accent: TeslaDriveDashboard::MINT
            end
            power = area_chart state.power_curve, id: :power_curve, width: 900, height: 78,
                               color: TeslaDriveDashboard::LIME, fill_color: "#2ec9ff18",
                               grid_color: "#202833", minimum: 0, maximum: 100,
                               line_width: 2, show_grid: true
            bind(power, :values) { state.power_curve }
          end
        end
        rectangle width: 446, height: 152, padding: 14, color: TeslaDriveDashboard::PANEL_ALT,
                  radius: 20, border_color: TeslaDriveDashboard::LINE, border_width: 1 do
          column spacing: 11 do
            text "CURRENT TRIP", size: 15, bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
            row spacing: 14 do
              column spacing: 2, width: 126 do
                text "DISTANCE", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
                distance = text "#{state.trip_distance.round(1)} mi", id: :trip_distance,
                                size: 16, bold: true, color: TeslaDriveDashboard::LIME, wrap: false
                bind(distance, :text) { "#{state.trip_distance.round(1)} mi" }
              end
              column spacing: 2, width: 126 do
                text "EFFICIENCY", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
                efficiency = text "#{(100 - state.traction * 0.08).round(1)}%", id: :trip_efficiency,
                                  size: 16, bold: true, color: TeslaDriveDashboard::MINT, wrap: false
                bind(efficiency, :text) { "#{(100 - state.traction * 0.08).round(1)}%" }
              end
              column spacing: 2, width: 126 do
                text "ARRIVAL", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
                arrival = text "#{[(state.route_miles / [state.speed, 1].max * 60).round, 1].max} min",
                               id: :trip_arrival, size: 16, bold: true,
                               color: TeslaDriveDashboard::WHITE, wrap: false
                bind(arrival, :text) do
                  "#{[(state.route_miles / [state.speed, 1].max * 60).round, 1].max} min"
                end
              end
            end
            text "Snowline Pass · Supercharger available on arrival", style: :caption,
                 color: TeslaDriveDashboard::MUTED, width: 410, wrap: false
          end
        end
      end
    end

    def reference_drive_hero
      row spacing: 14, alignment: :start do
        rectangle width: 568, height: 540, padding: 16, color: "#0b0c0c", radius: 22,
                  border_color: "#2a2d2d", border_width: 1 do
          column spacing: 12 do
            rectangle width: 536, height: 58, padding: 9, color: "#1a1d1c", radius: 14 do
              row spacing: 11, alignment: :center do
                rectangle width: 38, height: 38, radius: 10, color: "#32151b" do
                  icon :warning, size: 16, color: TeslaDriveDashboard::RED
                end
                column spacing: 0, width: 390 do
                  text "EMERGENCY ASSIST", bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
                  text "Hold only for roadside emergency", style: :caption,
                       color: TeslaDriveDashboard::MUTED, wrap: false
                end
                emergency = toggle_switch id: :emergency_switch, checked: state.emergency,
                                          rounded: true, track_width: 46, track_height: 24,
                                          knob_size: 18, knob_inset: 3, foreground: "#ffffff",
                                          accent: TeslaDriveDashboard::RED do |event|
                  state.emergency = event.fetch("value", false) == true
                end
                bind(emergency, :checked) { state.emergency }
              end
            end

            rectangle width: 536, height: 214, padding: 10, color: "#121413", radius: 18,
                      border_color: "#242827", border_width: 1 do
              stack width: 516, height: 194 do
                hero_image = image vehicle_image_source, id: :vehicle_hero_image,
                                   width: 516, height: 194, fill_mode: :preserve_aspect_crop,
                                   asynchronous: true, cache: true, smooth: true, mipmap: true
                bind(hero_image, :source) { vehicle_image_source }
                bind(hero_image, :scale, animation: { duration: 650, easing: :in_out_cubic }) do
                  state.driving ? (state.drive_motion ? 1.025 : 1.0) : 1.0
                end
                on(hero_image, :loaded) { state.image_ready = true }

                gradient colors: ["#5404080c", "#0004080c", "#6604080c"],
                         stops: [0.0, 0.5, 1.0], width: 516, height: 194,
                         start_x: 0, end_x: 516, radius: 12

                motion = particle_system id: :vehicle_motion_particles,
                                         width: 516, height: 194, running: state.driving,
                                         emit_rate: 18, life_span: 850, maximum_emitted: 28,
                                         size: 3, end_size: 1, size_variation: 2,
                                         color: TeslaDriveDashboard::CYAN, alpha: 0.28,
                                         emitter_x: 0, emitter_y: 150,
                                         emitter_width: 516, emitter_height: 42,
                                         velocity_angle: 180, velocity: 65,
                                         velocity_angle_variation: 8, velocity_variation: 24
                bind(motion, :running) { state.driving }

                rectangle width: 516, height: 194, padding: 10, color: "transparent" do
                  row spacing: 0, alignment: :center do
                    column spacing: 10, width: 104 do
                      round_button "", id: :left_camera, icon: :arrow_left, diameter: 42,
                                   foreground: TeslaDriveDashboard::LIME, background: "#bf111514",
                                   accent: TeslaDriveDashboard::LIME do
                        select_vehicle_view(-1)
                      end
                      charge = button state.charge_port_open ? "Close port" : "Charge",
                                      id: :charge_port_toggle, icon: :power, bordered: true,
                                      width: 104, foreground: TeslaDriveDashboard::WHITE,
                                      background: "#d9191d1c", accent: TeslaDriveDashboard::LIME do
                        toggle_vehicle_panel(:charge_port_open)
                      end
                      bind(charge, :text) { state.charge_port_open ? "Close port" : "Charge" }
                    end

                    spacer width: 288

                    column spacing: 10, width: 104 do
                      round_button "", id: :right_camera, icon: :arrow_right, diameter: 42,
                                   foreground: TeslaDriveDashboard::LIME, background: "#bf111514",
                                   accent: TeslaDriveDashboard::LIME do
                        select_vehicle_view(1)
                      end
                      trunk = button state.trunk_open ? "Close trunk" : "Trunk", id: :trunk_toggle,
                                     icon: :upload, bordered: true, width: 104,
                                     foreground: TeslaDriveDashboard::WHITE,
                                     background: "#d9191d1c", accent: TeslaDriveDashboard::LIME do
                        toggle_vehicle_panel(:trunk_open)
                      end
                      bind(trunk, :text) { state.trunk_open ? "Close trunk" : "Trunk" }
                    end
                  end
                end

              end
            end

            row spacing: 14, alignment: :center do
              speed = radial_gauge [], id: :vehicle_speed, value: state.speed,
                                   minimum: 0, maximum: 140, width: 205, height: 205,
                                   color: TeslaDriveDashboard::LIME, track_color: "#242827",
                                   thickness: 12, label: "SPEED · MPH", label_format: "%{value}"
              bind(speed, :value) { state.speed }
              column spacing: 10, width: 310 do
                row spacing: 10, alignment: :center do
                  gear = badge state.driving ? "D" : "P", id: :drive_gear, size: 38,
                               background: TeslaDriveDashboard::LIME, foreground: "#0a0b0b", font_size: 16
                  bind(gear, :value) { state.driving ? "D" : "P" }
                  autopilot = toggle_switch id: :autopilot_switch, checked: state.autopilot,
                                            rounded: true, track_width: 46, track_height: 24,
                                            knob_size: 18, knob_inset: 3, foreground: "#ffffff",
                                            accent: TeslaDriveDashboard::LIME do |event|
                    state.autopilot = event.fetch("value", false) == true
                  end
                  bind(autopilot, :checked) { state.autopilot }
                  pilot = text state.autopilot ? "AUTOSTEER" : "MANUAL", id: :autopilot_status,
                               style: :caption, bold: true, color: TeslaDriveDashboard::LIME, wrap: false
                  bind(pilot, :text) { state.autopilot ? "AUTOSTEER" : "MANUAL" }
                end
                drive = button state.driving ? "PAUSE SIMULATION" : "START DRIVE", id: :drive_toggle,
                               icon: state.driving ? :pause : :play,
                               bordered: false, foreground: "#090a0a", background: TeslaDriveDashboard::LIME,
                               accent: TeslaDriveDashboard::LIME, vertical_padding: 10 do
                  transaction do
                    starting = !state.driving
                    state.trunk_open = false if starting
                    state.charge_port_open = false if starting
                    state.speed = 0 unless starting
                    state.driving = starting
                  end
                end
                bind(drive, :text) { state.driving ? "PAUSE SIMULATION" : "START DRIVE" }
                bind(drive, :icon) { state.driving ? "pause" : "play" }
                row spacing: 18 do
                  drive_metric "POWER", "0 kW", id: :drive_power,
                               color: TeslaDriveDashboard::LIME, width: 88 do
                    "#{state.driving ? (state.speed * 2.4).round : 0} kW"
                  end
                  drive_metric "TRACTION", "0%", id: :drive_traction, width: 88 do
                    "#{state.driving ? state.traction : 0}%"
                  end
                  drive_metric "CAMERA", "#{state.camera_angle}°", id: :drive_camera,
                               color: TeslaDriveDashboard::CYAN, width: 88 do
                    "#{state.camera_angle}°"
                  end
                end
              end
            end
          end
        end

        column spacing: 14 do
          rectangle width: 350, height: 260, padding: 16, color: "#1a1c1b", radius: 20,
                    border_color: "#303432", border_width: 1 do
            column spacing: 10 do
              row spacing: 8, alignment: :center do
                column spacing: 0, width: 242 do
                  text "CLIMATE", size: 16, bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
                  climate_status = text state.climate ? "INTERIOR · AUTO" : "CLIMATE SLEEPING",
                                        id: :climate_status, style: :caption,
                                        color: TeslaDriveDashboard::MUTED, wrap: false
                  bind(climate_status, :text) { state.climate ? "INTERIOR · AUTO" : "CLIMATE SLEEPING" }
                end
                climate = toggle_switch id: :climate_switch, checked: state.climate,
                                        rounded: true, track_width: 46, track_height: 24,
                                        knob_size: 18, knob_inset: 3, foreground: "#ffffff",
                                        accent: TeslaDriveDashboard::LIME do |event|
                  state.climate = event.fetch("value", false) == true
                end
                bind(climate, :checked) { state.climate }
              end
              row spacing: 13, alignment: :center do
                temperature = text format("%.1f°C", state.cabin_temperature), id: :cabin_temperature,
                                   size: 40, bold: true, color: TeslaDriveDashboard::WHITE, width: 198, wrap: false
                bind(temperature, :text) { format("%.1f°C", state.cabin_temperature) }
                round_button "", id: :temperature_down, icon: :minus, diameter: 42,
                             foreground: TeslaDriveDashboard::WHITE, background: "#292c2b",
                             accent: TeslaDriveDashboard::LIME do
                  state.cabin_temperature = [state.cabin_temperature - 0.5, 16.0].max
                end
                round_button "", id: :temperature_up, icon: :plus, diameter: 42,
                             foreground: "#090a0a", background: TeslaDriveDashboard::LIME,
                             accent: TeslaDriveDashboard::LIME do
                  state.cabin_temperature = [state.cabin_temperature + 0.5, 28.0].min
                end
              end
              climate_slider = slider state.cabin_temperature, id: :climate_temperature_slider,
                                      minimum: 16, maximum: 28, step: 0.5, width: 318,
                                      track_color: "#303432", fill_color: TeslaDriveDashboard::LIME,
                                      knob_color: TeslaDriveDashboard::WHITE, track_height: 5, knob_size: 15 do |event|
                state.cabin_temperature = event.fetch("value", 21).to_f.round(1)
              end
              bind(climate_slider, :value) { state.cabin_temperature }
              row spacing: 10, alignment: :center do
                seat = button "SEAT HEAT · #{state.seat_heat}", id: :seat_heat, icon: :user,
                              bordered: true, foreground: TeslaDriveDashboard::WHITE,
                              background: "#222524", accent: TeslaDriveDashboard::LIME do
                  state.seat_heat = (state.seat_heat + 1) % 4
                end
                bind(seat, :text) { "SEAT HEAT · #{state.seat_heat}" }
                text "WINDOWS CLOSED", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
              end
            end
          end

          rectangle width: 350, height: 266, padding: 16, color: "#1a1c1b", radius: 20,
                    border_color: "#303432", border_width: 1 do
            column spacing: 9 do
              row spacing: 8, alignment: :center do
                text "ENERGY & TRIP", size: 16, bold: true, width: 218,
                     color: TeslaDriveDashboard::WHITE, wrap: false
                badge "#{state.charge.round}%", id: :charge_badge, size: 28,
                      background: "#2b3517", foreground: TeslaDriveDashboard::LIME
              end
              row spacing: 14, alignment: :center do
                battery = radial_gauge [], id: :battery_gauge, value: state.charge,
                                       minimum: 0, maximum: 100, width: 142, height: 142,
                                       color: TeslaDriveDashboard::LIME, track_color: "#303432",
                                       thickness: 11, label: "BATTERY", label_format: "%{value}%"
                bind(battery, :value) { state.charge }
                column spacing: 12, width: 162 do
                  drive_metric "EST. RANGE", "#{state.range.round(1)} mi", id: :drive_range,
                               color: TeslaDriveDashboard::LIME, width: 160 do
                    "#{state.range.round(1)} mi"
                  end
                  drive_metric "ROUTE LEFT", "#{state.route_miles.round(1)} mi",
                               id: :drive_route_left, width: 160 do
                    "#{state.route_miles.round(1)} mi"
                  end
                  charge_plan = button "PLAN CHARGE", id: :plan_charge,
                                       bordered: true, foreground: TeslaDriveDashboard::WHITE,
                                       background: "#222524", accent: TeslaDriveDashboard::LIME do
                    state.charge_dialog = true
                  end
                end
              end
              row spacing: 7 do
                %w[Chill Standard Sport].each do |mode|
                  mode_button = button mode.upcase, id: "mode.#{mode.downcase}",
                                       active: state.mode == mode, bordered: true,
                                       foreground: state.mode == mode ? "#090a0a" : TeslaDriveDashboard::MUTED,
                                       background: state.mode == mode ? TeslaDriveDashboard::LIME : "#202322",
                                       accent: TeslaDriveDashboard::LIME, font_size: 10 do
                    state.mode = mode
                  end
                  bind(mode_button, :active) { state.mode == mode }
                  bind(mode_button, :background) { state.mode == mode ? TeslaDriveDashboard::LIME : "#202322" }
                  bind(mode_button, :foreground) { state.mode == mode ? "#090a0a" : TeslaDriveDashboard::MUTED }
                end
              end
            end
          end
        end
      end
    end

    def reference_drive_side_panel
      column spacing: 14 do
        rectangle width: 446, height: 388, padding: 16, color: "#1a1c1b", radius: 20,
                  border_color: "#303432", border_width: 1 do
          column spacing: 9 do
            rectangle width: 414, height: 66, padding: 10, color: "#262927", radius: 13 do
              row spacing: 12, alignment: :center do
                rectangle width: 44, height: 44, radius: 12, color: TeslaDriveDashboard::LIME do
                  icon :arrow_left, size: 20, color: "#090a0a"
                end
                column spacing: 0, width: 274 do
                  text "500 m · TURN LEFT", size: 16, bold: true,
                       color: TeslaDriveDashboard::WHITE, wrap: false
                  remaining = text "#{state.route_miles.round(1)} mi · 6 min", id: :route_remaining,
                                   style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
                  bind(remaining, :text) { "#{state.route_miles.round(1)} mi · Snowline Pass" }
                end
                button "END", id: :end_route, bordered: false, foreground: TeslaDriveDashboard::RED,
                       background: "transparent", accent: TeslaDriveDashboard::RED do
                  state.driving = false
                end
              end
            end
            map = canvas drive_map_commands, id: :route_map, width: 414, height: 278,
                         background: "#171918", antialiasing: true, smooth: true
            bind(map, :commands) { drive_map_commands }
          end
        end

        rectangle width: 446, height: 138, padding: 14, color: "#1a1c1b", radius: 20,
                  border_color: "#303432", border_width: 1 do
          row spacing: 12, alignment: :center do
            gradient colors: [TeslaDriveDashboard::LIME, TeslaDriveDashboard::CYAN, "#7768ff"],
                     type: :conical, width: 86, height: 86, radius: 14
            column spacing: 4, width: 208 do
              text "GLASS HORIZON", bold: true, color: TeslaDriveDashboard::WHITE, wrap: false
              text "NOCTURNE SESSIONS", style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
              media_progress = progress state.media_position, id: :vehicle_media_progress,
                                        minimum: 0, maximum: state.media_duration, width: 196, height: 5,
                                        color: TeslaDriveDashboard::LIME
              bind(media_progress, :value) { state.media_position }
              bind(media_progress, :maximum) { state.media_duration }
              text "#{state.media_position.round}s / #{state.media_duration.round}s", id: :vehicle_media_time,
                   style: :caption, color: TeslaDriveDashboard::MUTED, wrap: false
            end
            media = round_button "", id: :media_toggle,
                                 icon: state.media_playing ? :pause : :play, diameter: 48,
                                 foreground: "#090a0a", background: TeslaDriveDashboard::LIME,
                                 accent: TeslaDriveDashboard::LIME do
              state.media_playing = !state.media_playing
            end
            bind(media, :icon) { state.media_playing ? "pause" : "play" }
          end
        end
      end
    end

    def tesla_drive_screen
      column spacing: 14 do
        drive_header
        row spacing: 14, alignment: :start do
          reference_drive_hero
          reference_drive_side_panel
        end
        drive_bottom
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :speed, 0
      state :charge, 82
      state :range, 286
      state :traction, 61
      state :mode, "Sport"
      state :driving, false
      state :climate, true
      state :locked, true
      state :autopilot, true
      state :charge_port_open, false
      state :trunk_open, false
      state :cabin_temperature, 21.0
      state :seat_heat, 1
      state :media_playing, true
      state :route_miles, 42.0
      state :route_progress, 0.0
      state :trip_distance, 0.0
      state :image_ready, false
      state :charge_dialog, false
      state :destination_search, ""
      state :emergency, false
      state :camera_angle, -45
      state :vehicle_view, 0
      state :drive_motion, false
      state :media_position, 0.0
      state :media_duration, 49.0
      state :power_curve, [18, 26, 21, 38, 46, 42, 58, 65, 59, 72, 68, 84, 76, 91]

      app :main, title: "Tesla Drive Lab · Electric Cockpit", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        media_player = audio "assets/cockpit-loop.ogg", id: :drive_media_player,
                             auto_play: false, playback: state.media_playing ? :play : :pause,
                             volume: 0.5, loops: 1
        bind(media_player, :playback) { state.media_playing ? "play" : "pause" }
        on(media_player, :position) do |event|
          state.media_position = (event.fetch("value", 0).to_f / 1000).round(2)
        end
        on(media_player, :duration) do |event|
          duration = (event.fetch("value", 0).to_f / 1000).round(2)
          state.media_duration = duration if duration.positive?
        end
        on(media_player, :end) do
          state.media_position = 0.0
          state.media_playing = false
        end
        tesla_drive_screen
        charge_dialog = alert_dialog "Route energy optimized", "12-minute charge recommended",
                                     id: :charge_dialog, severity: :info, opened: false,
                                     centered: true, standard_buttons: [:ok], width: 470, height: 330,
                                     informative_text: "Snowline Supercharger · 42 miles · 18 stalls available",
                                     background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                                     foreground: WHITE, muted: MUTED, accent: CYAN, button_accent: CYAN,
                                     border_color: LINE
        bind(charge_dialog, :opened) { state.charge_dialog }
        on(charge_dialog, :accept) { state.charge_dialog = false }
        on(charge_dialog, :close) { state.charge_dialog = false }
      end

      every(0.8) do
        if state.driving
          next_speed = state.speed >= 92 ? 58 : state.speed + 3
          distance_step = next_speed.to_f / 520.0
          transaction do
            state.speed = next_speed
            state.traction = 48 + (next_speed % 37)
            state.power_curve = state.power_curve.drop(1) + [next_speed]
            state.trip_distance = state.trip_distance + distance_step
            state.route_miles = [state.route_miles - distance_step, 0.0].max
            state.route_progress = [state.route_progress + distance_step * 2.3, 100.0].min
            state.charge = [state.charge - distance_step * 0.035, 0.0].max.round(1)
            state.range = [state.range - distance_step, 0.0].max.round(1)
            state.drive_motion = !state.drive_motion
          end
        end
      end
    end
  end

  def self.run = build.run
end
