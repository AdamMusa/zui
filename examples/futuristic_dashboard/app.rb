# frozen_string_literal: true

require "zui"
require_relative "components/dashboard"

module FuturisticDashboard
  def self.build
    Zui::Application.new(ui: UI) do
      state :tick, 0
      state :active_section, "Overview"
      state :boost, false
      state :ai_online, true
      state :scan_active, false
      state :scan_dialog, false
      state :packet_rate, 72.4
      state :core_temp, 38
      state :latency, 12.6
      state :shield, 87
      state :power, 73
      state :threats, 3
      state :signal, [38, 42, 39, 48, 51, 47, 58, 63, 61, 70, 68, 76, 73, 82, 78, 86]
      state :temperature_signal, [31, 33, 32, 34, 35, 34, 36, 37, 36, 38, 37, 39, 38, 40, 39, 38]
      state :latency_signal, [28, 24, 25, 21, 23, 19, 18, 20, 17, 16, 14, 15, 13, 14, 12, 13]
      state :events, [
        { title: "Relay lattice aligned", detail: "18 quantum nodes synchronized", color: CYAN },
        { title: "Helios gate acquired", detail: "Transit window opens in 04:12", color: VIOLET },
        { title: "Three anomalies queued", detail: "Copilot classification pending", color: ROSE }
      ]

      app :main, title: "Nebula Command · Futuristic Dashboard", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        nebula_dashboard

        scan_result = alert_dialog "Deep scan complete", "Seven signatures classified", id: :scan_result_dialog,
                                   severity: :success, opened: false, standard_buttons: [:ok],
                                   centered: true,
                                   image: "assets/neural-core.svg", image_height: 150,
                                   image_fill_mode: :preserve_aspect_fit, width: 480, height: 430,
                                   informative_text: "No hostile intent detected · Sector lattice 7A–9F",
                                   header_background: PANEL_ALT, footer_background: PANEL_ALT,
                                   background: PANEL, foreground: FOREGROUND, muted: MUTED,
                                   accent: CYAN, button_accent: CYAN, border_color: BORDER
        bind(scan_result, :opened) { state.scan_dialog }
        on(scan_result, :close) { state.scan_dialog = false }
        on(scan_result, :accept) { state.scan_dialog = false }
      end

      every(1.0) do
        next_tick = state.tick.to_i + 1
        throughput = 56 + ((next_tick * 11) % 37)
        temperature = 35 + ((next_tick * 3) % 8)
        latency = 11 + ((next_tick * 7) % 8) / 10.0

        transaction do
          state.tick = next_tick
          state.packet_rate = throughput + ((next_tick % 5) / 10.0)
          state.core_temp = temperature
          state.latency = latency
          state.signal = state.signal.drop(1) + [throughput]
          state.temperature_signal = state.temperature_signal.drop(1) + [temperature]
          state.latency_signal = state.latency_signal.drop(1) + [latency * 4]
          state.shield = 84 + (next_tick % 11)
          state.power = state.boost ? 94 + (next_tick % 5) : 70 + (next_tick % 8)
        end
      end
    end
  end

  def self.run = build.run
end
