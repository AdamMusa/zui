# frozen_string_literal: true

module FuturisticDashboard
  CYAN = "#56e6ff"
  VIOLET = "#a47cff"
  MINT = "#5dffb3"
  ROSE = "#ff638d"
  GOLD = "#ffd166"
  INK = "#050810"
  PANEL = "#0b1220"
  PANEL_ALT = "#0e1828"
  BORDER = "#1b3548"
  FOREGROUND = "#e8f7ff"
  MUTED = "#7890a4"

  NAVIGATION = [
    ["Overview", :house],
    ["Star map", :globe],
    ["Fleet", :wifi],
    ["Signals", :terminal],
    ["Archives", :folder]
  ].freeze

  module UI
    def nebula_clock
      seconds = state.tick.to_i % 60
      "23:49:#{seconds < 10 ? "0#{seconds}" : seconds}"
    end

    def nebula_percent(value)
      "#{value.to_i}%"
    end

    def nebula_push_event(title, detail, color)
      entry = { title: title, detail: detail, color: color }
      state.events = [entry] + state.events.first(2)
    end

    def nebula_header
      rectangle width: 1392, height: 76, padding: 14, color: FuturisticDashboard::PANEL,
                radius: 18, border_color: FuturisticDashboard::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          rectangle width: 46, height: 46, radius: 15, color: "#102b3a",
                    border_color: FuturisticDashboard::CYAN, border_width: 1 do
            text "N", size: 22, bold: true, color: FuturisticDashboard::CYAN, wrap: false
          end

          column spacing: 2, width: 294 do
            text "NEBULA COMMAND", size: 18, bold: true, color: FuturisticDashboard::FOREGROUND, wrap: false
            text "ORBITAL INTELLIGENCE / NX-07", style: :caption, color: FuturisticDashboard::MUTED, wrap: false
          end

          spacer width: 570

          chip "UPLINK STABLE", selected: true, icon: :wifi, background: "#102132",
                               selected_background: "#103126", foreground: FuturisticDashboard::MINT,
                               selected_foreground: FuturisticDashboard::MINT, accent: FuturisticDashboard::MINT

          column spacing: 1, width: 104 do
            text "SHIP TIME", style: :caption, color: FuturisticDashboard::MUTED, wrap: false
            clock = text nebula_clock, id: :ship_clock, bold: true, color: FuturisticDashboard::FOREGROUND, wrap: false
            bind(clock, :text) { nebula_clock }
          end

          badge "A7", size: 36, minimum_width: 36, background: FuturisticDashboard::VIOLET,
                      foreground: FuturisticDashboard::INK
        end
      end
    end

    def nebula_navigation
      rectangle width: 190, height: 708, padding: 14, color: FuturisticDashboard::PANEL,
                radius: 18, border_color: FuturisticDashboard::BORDER, border_width: 1 do
        column spacing: 8 do
          text "COMMAND DECK", style: :caption, color: FuturisticDashboard::MUTED, width: 162, wrap: false

          FuturisticDashboard::NAVIGATION.each do |label, icon_name|
            item = item_delegate label, id: "nav.#{label.downcase.gsub(" ", "_")}", value: label,
                                       icon: icon_name, width: 162, height: 52, radius: 12,
                                       padding: 12, spacing: 14, icon_size: 23,
                                       selected: state.active_section == label,
                                       background: "transparent", selected_background: "#102b3a",
                                       highlighted_background: "#102b3a", foreground: "#a9bdca",
                                       selected_foreground: FuturisticDashboard::CYAN,
                                       icon_color: FuturisticDashboard::CYAN, muted: FuturisticDashboard::MUTED,
                                       border_color: state.active_section == label ? "#265a70" : "transparent" do
              state.active_section = label
            end
            bind(item, :selected) { state.active_section == label }
            bind(item, :border_color) { state.active_section == label ? "#265a70" : "transparent" }
          end

          rectangle width: 1, height: 222, color: "transparent"
          divider length: 162, color: FuturisticDashboard::BORDER, opacity: 0.9

          rectangle width: 162, height: 92, padding: 11, color: "#0d1926", radius: 13,
                    border_color: "#1d4050", border_width: 1 do
            column spacing: 5 do
              row spacing: 8, alignment: :center do
                badge "", dot: true, size: 9, background: FuturisticDashboard::MINT
                text "CORE ONLINE", style: :caption, bold: true, color: FuturisticDashboard::MINT, wrap: false
              end
              text "All 18 nodes responding", style: :caption, color: FuturisticDashboard::MUTED,
                   width: 138, wrap: true
            end
          end
        end
      end
    end

    def nebula_hero
      stack do
        hero = rectangle id: :command_hero, width: 808, height: 202, padding: 18,
                         color: "#0a1423", radius: 18, border_color: FuturisticDashboard::CYAN,
                         border_width: 1 do
          row spacing: 28, alignment: :center do
            column spacing: 10, width: 520 do
              row spacing: 9, alignment: :center do
                chip "LIVE MISSION", selected: true, background: "#172235", selected_background: "#15322d",
                                     foreground: FuturisticDashboard::MINT,
                                     selected_foreground: FuturisticDashboard::MINT,
                                     accent: FuturisticDashboard::MINT, font_size: 11
                status_badge = badge state.boost ? "OVERDRIVE" : "NOMINAL", id: :mode_badge,
                                     size: 24, background: state.boost ? FuturisticDashboard::ROSE : FuturisticDashboard::VIOLET,
                                     foreground: FuturisticDashboard::INK, font_size: 10
                bind(status_badge, :value) { state.boost ? "OVERDRIVE" : "NOMINAL" }
                bind(status_badge, :background) { state.boost ? FuturisticDashboard::ROSE : FuturisticDashboard::VIOLET }
              end

              headline = text "HELIOS GATE / SYNCHRONIZED", id: :mission_headline, size: 24, bold: true,
                              color: FuturisticDashboard::FOREGROUND, width: 510, wrap: false
              bind(headline, :text) do
                state.scan_active ? "DEEP SPACE SCAN / ACTIVE" : "HELIOS GATE / SYNCHRONIZED"
              end

              subtitle = text "Neural routing is balancing the fleet across 18 quantum relays.",
                              id: :mission_subtitle, color: "#91a8b8", width: 500, wrap: true
              bind(subtitle, :text) do
                state.scan_active ? "Sweeping sectors 7A–9F for non-human signal signatures." :
                  "Neural routing is balancing the fleet across 18 quantum relays."
              end

              row spacing: 10, alignment: :center do
                scan = button(state.scan_active ? "Scanning…" : "Initiate scan", id: :scan_button,
                              icon: state.scan_active ? :refresh : :search, active: state.scan_active,
                              bordered: true, foreground: FuturisticDashboard::CYAN,
                              background: "#0c2230", accent: FuturisticDashboard::CYAN,
                              icon_spinning: state.scan_active) do
                  unless state.scan_active
                    transaction do
                      state.scan_active = true
                      state.threats = 0
                      nebula_push_event("Deep scan started", "Sector lattice 7A–9F", FuturisticDashboard::CYAN)
                    end
                    after(2.4) do
                      transaction do
                        state.scan_active = false
                        state.threats = 7
                        state.scan_dialog = true
                        nebula_push_event("Anomalies resolved", "7 signatures classified", FuturisticDashboard::MINT)
                      end
                    end
                  end
                end
                bind(scan, :text) { state.scan_active ? "Scanning…" : "Initiate scan" }
                bind(scan, :active) { state.scan_active }
                bind(scan, :icon) { state.scan_active ? "refresh" : "search" }
                bind(scan, :icon_spinning) { state.scan_active }

                boost = button(state.boost ? "Disengage boost" : "Engage overdrive", id: :boost_button,
                               icon: :power, bordered: false, active: state.boost,
                               foreground: state.boost ? FuturisticDashboard::ROSE : FuturisticDashboard::FOREGROUND,
                               background: "transparent", accent: FuturisticDashboard::ROSE) do
                  transaction do
                    state.boost = !state.boost
                    state.power = state.boost ? 96 : 73
                    nebula_push_event(state.boost ? "Overdrive engaged" : "Overdrive released",
                                      state.boost ? "Reactor ceiling raised" : "Nominal envelope restored",
                                      state.boost ? FuturisticDashboard::ROSE : FuturisticDashboard::VIOLET)
                  end
                end
                bind(boost, :text) { state.boost ? "Disengage boost" : "Engage overdrive" }
                bind(boost, :active) { state.boost }
                bind(boost, :foreground) { state.boost ? FuturisticDashboard::ROSE : FuturisticDashboard::FOREGROUND }
              end
            end

            image "assets/neural-core.svg", id: :neural_core_image, width: 190, height: 166,
                  fill_mode: :preserve_aspect_fit, asynchronous: true, cache: true, mipmap: true
          end
        end
        bind(hero, :border_color) { state.boost ? FuturisticDashboard::ROSE : FuturisticDashboard::CYAN }

        particle_system id: :hero_particles, width: 808, height: 202, source: "assets/particle.svg",
                        emit_rate: 16, life_span: 2400, life_span_variation: 700, maximum_emitted: 42,
                        size: 6, end_size: 1, size_variation: 4, color: FuturisticDashboard::CYAN,
                        color_variation: 0.35, alpha: 0.32, alpha_variation: 0.18,
                        emitter_x: 0, emitter_y: 170, emitter_width: 808, emitter_height: 20,
                        velocity_angle: 270, velocity: 18, velocity_angle_variation: 38,
                        velocity_variation: 10, turbulence: 12, turbulence_width: 808,
                        turbulence_height: 202, particle_shape: :ellipse
      end
    end

    def nebula_metric_card(id:, label:, color:, unit:, value_reader:, values_reader:)
      rectangle width: 260, height: 116, padding: 13, color: FuturisticDashboard::PANEL_ALT,
                radius: 15, border_color: "#1a3345", border_width: 1 do
        column spacing: 5 do
          row spacing: 8, alignment: :center do
            text label, style: :caption, bold: true, color: FuturisticDashboard::MUTED, width: 174, wrap: false
            badge "LIVE", size: 20, background: "#152536", foreground: color, font_size: 9
          end
          row spacing: 5, alignment: :end do
            metric_value = text value_reader.call, id: "metric.#{id}.value", size: 24, bold: true,
                                color: FuturisticDashboard::FOREGROUND, wrap: false
            bind(metric_value, :text) { value_reader.call }
            text unit, style: :caption, color: color, wrap: false
          end
          metric_chart = sparkline values_reader.call, id: "metric.#{id}.sparkline", width: 230, height: 29,
                                   color: color, fill_color: "transparent", line_width: 2,
                                   minimum: 0, maximum: 100, show_points: false
          bind(metric_chart, :values) { values_reader.call }
        end
      end
    end

    def nebula_metrics
      row spacing: 14, alignment: :start do
        nebula_metric_card id: :throughput, label: "QUANTUM THROUGHPUT", color: FuturisticDashboard::CYAN,
                           unit: "TB/s", value_reader: -> { state.packet_rate.to_s },
                           values_reader: -> { state.signal }
        nebula_metric_card id: :temperature, label: "CORE TEMPERATURE", color: FuturisticDashboard::GOLD,
                           unit: "°C", value_reader: -> { state.core_temp.to_s },
                           values_reader: -> { state.temperature_signal }
        nebula_metric_card id: :latency, label: "NEURAL LATENCY", color: FuturisticDashboard::VIOLET,
                           unit: "ms", value_reader: -> { state.latency.to_s },
                           values_reader: -> { state.latency_signal }
      end
    end

    def nebula_telemetry
      rectangle width: 808, height: 348, padding: 17, color: FuturisticDashboard::PANEL,
                radius: 18, border_color: FuturisticDashboard::BORDER, border_width: 1 do
        column spacing: 10 do
          row spacing: 8, alignment: :center do
            column spacing: 1, width: 470 do
              text "RELAY BANDWIDTH", size: 16, bold: true, color: FuturisticDashboard::FOREGROUND, wrap: false
              section = text "Overview / continuous telemetry", id: :section_context,
                             style: :caption, color: FuturisticDashboard::MUTED, wrap: false
              bind(section, :text) { "#{state.active_section} / continuous telemetry" }
            end
            chip "60 SEC", selected: true, background: "#122031", selected_background: "#15303d",
                           foreground: FuturisticDashboard::CYAN, selected_foreground: FuturisticDashboard::CYAN,
                           accent: FuturisticDashboard::CYAN
            chip "LIVE", selected: false, background: "#122031", foreground: FuturisticDashboard::MINT,
                         accent: FuturisticDashboard::MINT
          end

          telemetry = area_chart state.signal, id: :throughput_chart, width: 770, height: 216,
                                 color: FuturisticDashboard::CYAN, fill_color: "#2456e6ff",
                                 grid_color: "#183246", line_width: 2, minimum: 0, maximum: 100,
                                 show_grid: true
          bind(telemetry, :values) { state.signal }
          on(telemetry, :select) do |event|
            index = event.fetch("index", 0).to_i
            value = state.signal[index] || state.signal.last
            nebula_push_event("Telemetry pinned", "Relay sample #{index + 1}: #{value} TB/s",
                              FuturisticDashboard::CYAN)
          end

          row spacing: 22, alignment: :center do
            [["PEAK", "94.8 TB/s", FuturisticDashboard::CYAN],
             ["PACKETS", "8.41M", FuturisticDashboard::MINT],
             ["LOSS", "0.002%", FuturisticDashboard::VIOLET],
             ["RELAYS", "18 / 18", FuturisticDashboard::GOLD]].each do |label, value, color|
              column spacing: 1, width: 170 do
                text label, style: :caption, color: FuturisticDashboard::MUTED, wrap: false
                text value, bold: true, color: color, wrap: false
              end
            end
          end
        end
      end
    end

    def nebula_center
      column spacing: 14 do
        nebula_hero
        nebula_metrics
        nebula_telemetry
      end
    end

    def nebula_envelope
      rectangle width: 350, height: 235, padding: 14, color: FuturisticDashboard::PANEL,
                radius: 18, border_color: FuturisticDashboard::BORDER, border_width: 1 do
        column spacing: 5 do
          row spacing: 8, alignment: :center do
            text "SYSTEM ENVELOPE", size: 15, bold: true, width: 220,
                 color: FuturisticDashboard::FOREGROUND, wrap: false
            badge "STABLE", size: 22, background: "#153126", foreground: FuturisticDashboard::MINT, font_size: 9
          end
          radar_chart [87, 73, 94, 68, 82], id: :system_radar,
                      labels: ["SHIELD", "POWER", "NAV", "THERM", "AI"],
                      colors: [FuturisticDashboard::CYAN, FuturisticDashboard::VIOLET],
                      width: 318, height: 174, grid_color: "#254156", levels: 4,
                      fill_opacity: 0.2, line_width: 2, point_size: 3
        end
      end
    end

    def nebula_energy
      rectangle width: 350, height: 245, padding: 14, color: FuturisticDashboard::PANEL,
                radius: 18, border_color: FuturisticDashboard::BORDER, border_width: 1 do
        column spacing: 5 do
          row spacing: 8, alignment: :center do
            text "ENERGY MATRIX", size: 15, bold: true, width: 212,
                 color: FuturisticDashboard::FOREGROUND, wrap: false
            text "AUTO-BALANCE", style: :caption, color: FuturisticDashboard::MINT, wrap: false
          end

          row spacing: 10, alignment: :center do
            column spacing: 1 do
              shield = radial_gauge [], id: :shield_gauge, value: state.shield, minimum: 0, maximum: 100,
                                      width: 145, height: 145, color: FuturisticDashboard::CYAN,
                                      track_color: "#173140", thickness: 11,
                                      label_format: "%{value}%", label: "Shield", show_label: true
              bind(shield, :value) { state.shield }
              text "SHIELD ARRAY", style: :caption, bold: true, width: 145,
                   color: FuturisticDashboard::CYAN, wrap: false
            end
            column spacing: 1 do
              power = radial_gauge [], id: :power_gauge, value: state.power, minimum: 0, maximum: 100,
                                     width: 145, height: 145, color: FuturisticDashboard::VIOLET,
                                     track_color: "#2a2345", thickness: 11,
                                     label_format: "%{value}%", label: "Power", show_label: true
              bind(power, :value) { state.power }
              text "REACTOR LOAD", style: :caption, bold: true, width: 145,
                   color: FuturisticDashboard::VIOLET, wrap: false
            end
          end

          row spacing: 10, alignment: :center do
            text "NEURAL COPILOT", style: :caption, bold: true, width: 235,
                 color: FuturisticDashboard::MUTED, wrap: false
            ai_switch = toggle_switch id: :ai_switch, checked: state.ai_online,
                                      foreground: FuturisticDashboard::FOREGROUND,
                                      accent: FuturisticDashboard::MINT,
                                      rounded: true, cursor_ring: false,
                                      track_width: 44, track_height: 24,
                                      knob_size: 18, knob_inset: 3 do |event|
              state.ai_online = event.fetch("value", false) == true
              nebula_push_event("Neural copilot", state.ai_online ? "Autonomy restored" : "Manual command only",
                                state.ai_online ? FuturisticDashboard::MINT : FuturisticDashboard::ROSE)
            end
            bind(ai_switch, :checked) { state.ai_online }
          end
        end
      end
    end

    def nebula_event_row(index)
      entry = state.events[index]
      row spacing: 9, alignment: :center do
        marker = badge "", id: "event.#{index}.marker", dot: true, size: 8,
                       background: entry[:color]
        bind(marker, :background) { state.events[index][:color] }
        column spacing: 1, width: 275 do
          title = text entry[:title], id: "event.#{index}.title", bold: true, size: 12,
                       width: 275, color: FuturisticDashboard::FOREGROUND, wrap: false
          bind(title, :text) { state.events[index][:title] }
          detail = text entry[:detail], id: "event.#{index}.detail", style: :caption,
                        width: 275, color: FuturisticDashboard::MUTED, wrap: false
          bind(detail, :text) { state.events[index][:detail] }
        end
      end
    end

    def nebula_events
      rectangle width: 350, height: 200, padding: 14, color: FuturisticDashboard::PANEL,
                radius: 18, border_color: FuturisticDashboard::BORDER, border_width: 1 do
        column spacing: 9 do
          row spacing: 8, alignment: :center do
            text "MISSION STREAM", size: 15, bold: true, width: 222,
                 color: FuturisticDashboard::FOREGROUND, wrap: false
            threats = badge state.threats, id: :threat_badge, size: 24, minimum_width: 24,
                            background: state.threats.positive? ? FuturisticDashboard::ROSE : FuturisticDashboard::MINT,
                            foreground: FuturisticDashboard::INK
            bind(threats, :value) { state.threats }
            bind(threats, :background) { state.threats.positive? ? FuturisticDashboard::ROSE : FuturisticDashboard::MINT }
          end
          3.times { |index| nebula_event_row(index) }
        end
      end
    end

    def nebula_right_rail
      column spacing: 14 do
        nebula_envelope
        nebula_energy
        nebula_events
      end
    end

    def nebula_dashboard
      column spacing: 14 do
        nebula_header
        row spacing: 14, alignment: :start do
          nebula_navigation
          nebula_center
          nebula_right_rail
        end
      end
    end
  end
end
