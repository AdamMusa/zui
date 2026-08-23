# frozen_string_literal: true

require "zui"

module CardiacHealthMonitor
  INK = "#050a11"
  PANEL = "#0a1420"
  PANEL_ALT = "#101c29"
  BORDER = "#1d3446"
  WHITE = "#edfaff"
  MUTED = "#7894a6"
  CORAL = "#ff6f7d"
  RED = "#ff405d"
  CYAN = "#52e0ff"
  MINT = "#62f2b2"
  GOLD = "#ffd36a"

  ECG_PATTERN = [0, 1, 0, -1, 0, 2, 4, 3, 0, -4, 18, -7, 3, 0, 1, 0, -1, 0].freeze

  module UI
    def pulse_header
      rectangle width: 1392, height: 74, padding: 14, color: CardiacHealthMonitor::PANEL,
                radius: 20, border_color: CardiacHealthMonitor::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          rectangle width: 44, height: 44, radius: 14, color: "#32141d",
                    border_color: CardiacHealthMonitor::CORAL, border_width: 1 do
            icon :heart, size: 21, color: CardiacHealthMonitor::CORAL
          end
          column spacing: 1, width: 360 do
            text "PULSE ATLAS", size: 19, bold: true, color: CardiacHealthMonitor::WHITE, wrap: false
            text "CARDIAC WELLNESS / CONTINUOUS INSIGHT", style: :caption,
                 color: CardiacHealthMonitor::MUTED, wrap: false
          end
          spacer width: 610
          chip "SENSOR SYNCED", icon: :wifi, selected: true, background: "#12252a",
                                 selected_background: "#113126", foreground: CardiacHealthMonitor::MINT,
                                 selected_foreground: CardiacHealthMonitor::MINT, accent: CardiacHealthMonitor::MINT
          column spacing: 1, width: 120 do
            text "LAST SAMPLE", style: :caption, color: CardiacHealthMonitor::MUTED, wrap: false
            sample = text state.sample_time, id: :sample_time, bold: true,
                          color: CardiacHealthMonitor::WHITE, wrap: false
            bind(sample, :text) { state.sample_time }
          end
          badge "LIVE", size: 28, background: "#32141d", foreground: CardiacHealthMonitor::CORAL
        end
      end
    end

    def pulse_heart_visual
      stack do
        rectangle width: 450, height: 510, color: CardiacHealthMonitor::PANEL,
                  radius: 22, border_color: CardiacHealthMonitor::BORDER, border_width: 1
        image "assets/luminous-heart.png", id: :heart_image,
              width: 450, height: 510, fill_mode: :preserve_aspect_crop,
              asynchronous: true, cache: true, smooth: true, mipmap: true
        gradient colors: ["#00050a11", "#18050a11", "#d0050a11"], stops: [0.0, 0.58, 1.0],
                 width: 450, height: 510, start_y: 0, end_y: 510, radius: 22
        particle_system id: :heart_particles, width: 450, height: 510, running: state.monitoring,
                        emit_rate: 8, life_span: 1700, maximum_emitted: 24,
                        size: 5, end_size: 1, size_variation: 3,
                        color: CardiacHealthMonitor::CYAN, alpha: 0.3,
                        emitter_x: 40, emitter_y: 390, emitter_width: 370, emitter_height: 60,
                        velocity_angle: 270, velocity: 14, velocity_angle_variation: 30,
                        turbulence: 9, turbulence_width: 450, turbulence_height: 510
        rectangle width: 450, height: 510, padding: 18, color: "transparent", radius: 22 do
          column spacing: 300 do
            row spacing: 8, alignment: :center do
              chip "HEART IMAGE", id: :heart_render_mode,
                                  selected: true, background: "#23151d",
                                  selected_background: "#32141d", foreground: CardiacHealthMonitor::CORAL,
                                  selected_foreground: CardiacHealthMonitor::CORAL,
                                  accent: CardiacHealthMonitor::CORAL
            end
            column spacing: 3 do
              text "CARDIAC IMAGE", size: 18, bold: true, color: CardiacHealthMonitor::WHITE, wrap: false
              text "Live cardiac visualization", id: :heart_inspection_hint,
                   style: :caption, color: CardiacHealthMonitor::CYAN, width: 405, wrap: false
              text "Anatomical image · visualization only", style: :caption,
                   color: CardiacHealthMonitor::MUTED, width: 405, wrap: false
            end
          end
        end
      end
    end

    def pulse_waveform
      rectangle width: 614, height: 310, padding: 15, color: CardiacHealthMonitor::PANEL,
                radius: 20, border_color: CardiacHealthMonitor::BORDER, border_width: 1 do
        column spacing: 9 do
          row spacing: 8, alignment: :center do
            column spacing: 1, width: 420 do
              text "SINUS RHYTHM", size: 15, bold: true, color: CardiacHealthMonitor::WHITE, wrap: false
              text "Lead approximation · 25 mm/s", style: :caption,
                   color: CardiacHealthMonitor::MUTED, wrap: false
            end
            status = badge state.monitoring ? "MONITORING" : "PAUSED", id: :monitor_status,
                           size: 24, background: state.monitoring ? "#153326" : "#39221b",
                           foreground: state.monitoring ? CardiacHealthMonitor::MINT : CardiacHealthMonitor::GOLD,
                           font_size: 9
            bind(status, :value) { state.monitoring ? "MONITORING" : "PAUSED" }
            bind(status, :background) { state.monitoring ? "#153326" : "#39221b" }
            bind(status, :foreground) do
              state.monitoring ? CardiacHealthMonitor::MINT : CardiacHealthMonitor::GOLD
            end
          end
          ecg = line_chart state.ecg, id: :ecg_waveform, width: 582, height: 205,
                           color: CardiacHealthMonitor::CORAL, fill_color: "transparent",
                           grid_color: "#183143", line_width: 2, minimum: -10, maximum: 22,
                           show_grid: true, show_points: false
          bind(ecg, :values) { state.ecg }
          row spacing: 14 do
            [["GAIN", "10 mm/mV", CardiacHealthMonitor::CYAN],
             ["FILTER", "0.5–40 Hz", CardiacHealthMonitor::MINT],
             ["QUALITY", "Excellent", CardiacHealthMonitor::GOLD]].each do |label, value, color|
              column spacing: 1, width: 180 do
                text label, style: :caption, color: CardiacHealthMonitor::MUTED, wrap: false
                text value, bold: true, color: color, wrap: false
              end
            end
          end
        end
      end
    end

    def pulse_vitals
      row spacing: 14 do
        [["HEART RATE", :bpm, "BPM", CardiacHealthMonitor::CORAL],
         ["OXYGEN", :spo2, "%", CardiacHealthMonitor::CYAN],
         ["HRV", :hrv, "ms", CardiacHealthMonitor::MINT]].each do |label, state_name, unit, color|
          rectangle width: 195, height: 186, padding: 13, color: CardiacHealthMonitor::PANEL_ALT,
                    radius: 18, border_color: CardiacHealthMonitor::BORDER, border_width: 1 do
            column spacing: 6 do
              text label, style: :caption, bold: true, color: CardiacHealthMonitor::MUTED, wrap: false
              value = state.public_send(state_name)
              gauge = radial_gauge [], id: "#{state_name}.gauge", value: value,
                                   minimum: state_name == :bpm ? 40 : 0,
                                   maximum: state_name == :bpm ? 180 : 100,
                                   width: 165, height: 124, color: color,
                                   track_color: "#1b2b38", thickness: 9,
                                   label: unit, label_format: "%{value}"
              bind(gauge, :value) { state.public_send(state_name) }
            end
          end
        end
      end
    end

    def pulse_center
      column spacing: 14 do
        pulse_waveform
        pulse_vitals
      end
    end

    def pulse_guidance
      rectangle width: 300, height: 510, padding: 15, color: CardiacHealthMonitor::PANEL,
                radius: 20, border_color: CardiacHealthMonitor::BORDER, border_width: 1 do
        column spacing: 13 do
          text "RECOVERY GUIDE", size: 15, bold: true, color: CardiacHealthMonitor::WHITE, wrap: false
          spacer height: 6
          rectangle width: 268, height: 220, padding: 12, color: "transparent" do
            progress_ring state.recovery, id: :recovery_ring, minimum: 0, maximum: 100,
                          size: 184, width: 244, height: 196, thickness: 11,
                          track_color: "#19303b", color: CardiacHealthMonitor::MINT,
                          foreground: CardiacHealthMonitor::WHITE, label: "Readiness",
                          label_format: "%{value}%", show_label: true
          end
          column spacing: 4 do
            text "NERVOUS SYSTEM", style: :caption, color: CardiacHealthMonitor::MUTED, wrap: false
            text "Balanced", size: 18, bold: true, color: CardiacHealthMonitor::MINT, wrap: false
            text "Your overnight HRV is 8% above the 30-day baseline.", size: 12,
                 color: "#a9bcc8", width: 268, wrap: true
          end
          breathe = button(state.breathing ? "End breathing" : "Begin 4–6 breathing",
                           id: :breathing_toggle, icon: state.breathing ? :stop : :play,
                           active: state.breathing, bordered: true,
                           foreground: CardiacHealthMonitor::WHITE,
                           background: "#142832", accent: CardiacHealthMonitor::CYAN) do
            state.breathing = !state.breathing
          end
          bind(breathe, :text) { state.breathing ? "End breathing" : "Begin 4–6 breathing" }
          bind(breathe, :icon) { state.breathing ? "stop" : "play" }
          bind(breathe, :active) { state.breathing }
          report = button "View daily insight", id: :daily_insight, icon: :file,
                          bordered: false, foreground: CardiacHealthMonitor::CORAL,
                          background: "transparent", accent: CardiacHealthMonitor::CORAL do
            state.insight_dialog = true
          end
        end
      end
    end

    def pulse_bottom
      row spacing: 14 do
        rectangle width: 920, height: 230, padding: 14, color: CardiacHealthMonitor::PANEL,
                  radius: 20, border_color: CardiacHealthMonitor::BORDER, border_width: 1 do
          column spacing: 8 do
            row spacing: 8, alignment: :center do
              text "RECOVERY RHYTHM", size: 15, bold: true, width: 690,
                   color: CardiacHealthMonitor::WHITE, wrap: false
              chip "14 DAYS", selected: true, background: "#142832",
                              selected_background: "#142832", foreground: CardiacHealthMonitor::CYAN,
                              selected_foreground: CardiacHealthMonitor::CYAN,
                              accent: CardiacHealthMonitor::CYAN
            end
            heatmap [[62, 71, 76, 80, 74, 86, 90], [68, 73, 79, 82, 77, 89, 92],
                     [58, 69, 72, 78, 81, 84, 88]], id: :recovery_heatmap,
                    x_labels: %w[M T W T F S S], y_labels: ["HRV", "SLEEP", "LOAD"],
                    colors: ["#182635", "#23556c", CardiacHealthMonitor::CYAN, CardiacHealthMonitor::MINT],
                    width: 890, height: 160, minimum: 50, maximum: 100,
                    cell_spacing: 5, show_values: true, value_color: CardiacHealthMonitor::WHITE
          end
        end
        rectangle width: 458, height: 230, padding: 14, color: CardiacHealthMonitor::PANEL_ALT,
                  radius: 20, border_color: CardiacHealthMonitor::BORDER, border_width: 1 do
          column spacing: 10 do
            text "TODAY'S SIGNALS", size: 15, bold: true, color: CardiacHealthMonitor::WHITE, wrap: false
            [[CardiacHealthMonitor::MINT, "Sleep consistency", "8h 12m · strong"],
             [CardiacHealthMonitor::CYAN, "Respiratory rate", "13.2 / min · normal"],
             [CardiacHealthMonitor::GOLD, "Training load", "Moderate · 42 min"],
             [CardiacHealthMonitor::CORAL, "Resting pulse", "54 BPM · baseline"]].each do |color, title, detail|
              row spacing: 9, alignment: :center do
                badge "", dot: true, size: 8, background: color
                column spacing: 1 do
                  text title, bold: true, size: 12, width: 380,
                       color: CardiacHealthMonitor::WHITE, wrap: false
                  text detail, style: :caption, color: CardiacHealthMonitor::MUTED, wrap: false
                end
              end
            end
          end
        end
      end
    end

    def cardiac_screen
      column spacing: 14 do
        pulse_header
        row spacing: 14, alignment: :start do
          pulse_heart_visual
          pulse_center
          pulse_guidance
        end
        pulse_bottom
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :tick, 0
      state :bpm, 68
      state :spo2, 98
      state :hrv, 72
      state :recovery, 86
      state :monitoring, true
      state :breathing, false
      state :insight_dialog, false
      state :sample_time, "NOW"
      state :ecg, ECG_PATTERN * 3

      app :main, title: "Pulse Atlas · Cardiac Wellness", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        cardiac_screen
        insight = alert_dialog "Daily cardiac insight", "Recovery trend is strong",
                               id: :insight_dialog, severity: :success, opened: false,
                               centered: true, standard_buttons: [:ok], width: 500, height: 440,
                               image: "assets/luminous-heart.png", image_height: 180,
                               image_fill_mode: :preserve_aspect_fit,
                               informative_text: "Resting pulse and HRV remain inside your personal baseline.",
                               background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                               foreground: WHITE, muted: MUTED, accent: CORAL, button_accent: CORAL,
                               border_color: BORDER
        bind(insight, :opened) { state.insight_dialog }
        on(insight, :accept) { state.insight_dialog = false }
        on(insight, :close) { state.insight_dialog = false }
      end

      every(0.45) do
        next_tick = state.tick + 1
        if state.monitoring
          transaction do
            state.tick = next_tick
            state.bpm = 66 + (next_tick % 7)
            state.hrv = 69 + (next_tick % 8)
            state.spo2 = 97 + (next_tick % 2)
            state.sample_time = "#{next_tick % 5}s"
            state.ecg = state.ecg.drop(1) + [ECG_PATTERN[next_tick % ECG_PATTERN.length]]
          end
        end
      end
    end
  end

  def self.run = build.run
end
