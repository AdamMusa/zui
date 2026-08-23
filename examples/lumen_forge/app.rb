# frozen_string_literal: true

require "zui"

module ShaderStudio
  INK = "#06050c"
  PANEL = "#100d1d"
  PANEL_ALT = "#171228"
  BORDER = "#322750"
  WHITE = "#fbf8ff"
  MUTED = "#958aa9"
  MAGENTA = "#ff54d9"
  VIOLET = "#9c6cff"
  CYAN = "#4be8ff"
  LIME = "#b8ff68"

  SHADERS = %w[golden_apollian procedural_ocean star_nest hex_plasma synthwave_city].freeze

  module UI
    def forge_shader_source(name)
      "assets/shaders/#{name.tr('_', '-')}.frag.qsb"
    end

    def forge_shader_label(name)
      name.split("_").map { |part| part.capitalize }.join(" ")
    end

    def forge_shader_path(name)
      {
        "golden_apollian" => "Shadertoy WlcfRS · mrange · CC0",
        "procedural_ocean" => "Shadertoy MdXyzX · afl_ext · MIT",
        "star_nest" => "Shadertoy XlfGRj · Kali · MIT",
        "hex_plasma" => "Shadertoy 3fy3z3 · Nemerix · MIT",
        "synthwave_city" => "Shadertoy 7lKyDD · 3w36zj6 · CC BY 3.0"
      }.fetch(name)
    end

    def forge_shader_icon(name)
      return :globe if name == "procedural_ocean"
      return :star if %w[golden_apollian star_nest].include?(name)
      return :location if name == "synthwave_city"

      :code
    end

    def forge_shader_accent(name)
      return ShaderStudio::CYAN if name == "procedural_ocean"
      return ShaderStudio::LIME if name == "golden_apollian"
      return ShaderStudio::VIOLET if name == "star_nest"

      ShaderStudio::MAGENTA
    end

    def forge_label(label, value, id:, color: ShaderStudio::WHITE)
      row spacing: 8, alignment: :center do
        text label, style: :caption, bold: true, width: 250, color: ShaderStudio::MUTED, wrap: false
        output = text value, id: id, bold: true, color: color, wrap: false
        yield(output) if block_given?
      end
    end

    def forge_header
      rectangle width: 1392, height: 74, padding: 14, color: ShaderStudio::PANEL,
                radius: 20, border_color: ShaderStudio::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          gradient colors: [ShaderStudio::MAGENTA, ShaderStudio::VIOLET, ShaderStudio::CYAN],
                   type: :conical, width: 44, height: 44, radius: 14
          column spacing: 1, width: 360 do
            text "LUMEN FORGE", size: 19, bold: true, color: ShaderStudio::WHITE, wrap: false
            text "REAL-TIME GPU SHADER LABORATORY", style: :caption,
                 color: ShaderStudio::MUTED, wrap: false
          end
          spacer width: 590
          chip "QSB PIPELINE", icon: :code, selected: true, background: "#1d1730",
                               selected_background: "#1b2930", foreground: ShaderStudio::CYAN,
                               selected_foreground: ShaderStudio::CYAN, accent: ShaderStudio::CYAN
          badge "60 FPS", size: 30, background: "#20301b", foreground: ShaderStudio::LIME
          button "Export preset", id: :export_preset, icon: :save, bordered: true,
                 foreground: ShaderStudio::WHITE, background: "transparent", accent: ShaderStudio::MAGENTA do
            state.notice = true
          end
        end
      end
    end

    def forge_viewport
      rectangle width: 920, height: 566, padding: 14, color: ShaderStudio::PANEL,
                radius: 22, border_color: ShaderStudio::BORDER, border_width: 1 do
        column spacing: 10 do
          row spacing: 8, alignment: :center do
            column spacing: 1, width: 650 do
              text "LIVE OUTPUT", size: 15, bold: true, color: ShaderStudio::WHITE, wrap: false
              active = text forge_shader_path(state.shader), id: :active_shader_path,
                            style: :caption, color: ShaderStudio::MUTED, wrap: false
              bind(active, :text) { forge_shader_path(state.shader) }
            end
            shader_badge = chip state.shader.upcase, id: :shader_badge, selected: true,
                                background: "#281937", selected_background: "#281937",
                                foreground: ShaderStudio::MAGENTA, selected_foreground: ShaderStudio::MAGENTA,
                                accent: ShaderStudio::MAGENTA
            bind(shader_badge, :text) { state.shader.upcase }
          end

          effect = shader_effect nil, id: :live_shader, shader: forge_shader_source(state.shader),
                                 width: 890, height: 480, running: true, fps: 60,
                                 amount: state.amount, intensity: state.intensity,
                                 radius: state.radius, frequency: state.frequency,
                                 amplitude: state.amplitude, mouse_x: state.mouse_x,
                                 mouse_y: state.mouse_y, color: ShaderStudio::INK
          bind(effect, :shader) { forge_shader_source(state.shader) }
          bind(effect, :amount) { state.amount }
          bind(effect, :intensity) { state.intensity }
          bind(effect, :radius) { state.radius }
          bind(effect, :frequency) { state.frequency }
          bind(effect, :amplitude) { state.amplitude }
          bind(effect, :mouse_x) { state.mouse_x }
          bind(effect, :mouse_y) { state.mouse_y }
          on(effect, :click) do |event|
            state.mouse_x = event.fetch("x", 445).to_f
            state.mouse_y = event.fetch("y", 240).to_f
            state.pointer = "#{state.mouse_x.to_i}, #{state.mouse_y.to_i}"
          end
          on(effect, :hover) do |event|
            state.mouse_x = event.fetch("x", state.mouse_x).to_f
            state.mouse_y = event.fetch("y", state.mouse_y).to_f
            state.pointer = "#{state.mouse_x.to_i}, #{state.mouse_y.to_i}"
          end
        end
      end
    end

    def forge_slider(label, state_name, minimum:, maximum:, step:, color:)
      column spacing: 5 do
        current = state.public_send(state_name)
        row spacing: 8, alignment: :center do
          text label, style: :caption, bold: true, width: 292,
               color: ShaderStudio::MUTED, wrap: false
          value = text format("%.2f", current.to_f), id: "#{state_name}.value", bold: true,
                       color: color, wrap: false
          bind(value, :text) { format("%.2f", state.public_send(state_name).to_f) }
        end
        control = slider current, id: "#{state_name}.slider", minimum: minimum, maximum: maximum,
                         step: step, width: 402, track_color: "#29213c", fill_color: color,
                         knob_color: ShaderStudio::WHITE, track_height: 6, knob_size: 17 do |event|
          state.public_send("#{state_name}=", event.fetch("value", current).to_f)
        end
        bind(control, :value) { state.public_send(state_name) }
      end
    end

    def forge_controls
      column spacing: 14 do
        rectangle width: 458, height: 300, padding: 15, color: ShaderStudio::PANEL,
                  radius: 20, border_color: ShaderStudio::BORDER, border_width: 1 do
          column spacing: 10 do
            text "SHADER LIBRARY", size: 15, bold: true, color: ShaderStudio::WHITE, wrap: false
            ShaderStudio::SHADERS.each do |name|
              accent = forge_shader_accent(name)
              choice = item_delegate forge_shader_label(name), id: "shader.#{name}", value: name,
                                     icon: forge_shader_icon(name),
                                     width: 426, height: 43, padding: 9, spacing: 14,
                                     selected: state.shader == name, background: "transparent",
                                     selected_background: "#251a3a", foreground: ShaderStudio::MUTED,
                                     selected_foreground: ShaderStudio::WHITE,
                                     icon_color: accent,
                                     border_color: state.shader == name ? ShaderStudio::VIOLET : "transparent" do
                state.shader = name
              end
              bind(choice, :selected) { state.shader == name }
              bind(choice, :border_color) { state.shader == name ? ShaderStudio::VIOLET : "transparent" }
            end
          end
        end

        rectangle width: 458, height: 252, padding: 15, color: ShaderStudio::PANEL_ALT,
                  radius: 20, border_color: ShaderStudio::BORDER, border_width: 1 do
          column spacing: 9 do
            text "UNIFORMS", size: 15, bold: true, color: ShaderStudio::WHITE, wrap: false
            forge_slider "FREQUENCY", :frequency, minimum: 0.5, maximum: 8.0, step: 0.1,
                         color: ShaderStudio::CYAN
            forge_slider "AMPLITUDE", :amplitude, minimum: 0.0, maximum: 0.16, step: 0.01,
                         color: ShaderStudio::MAGENTA
            forge_slider "AMOUNT", :amount, minimum: 1.0, maximum: 40.0, step: 1.0,
                         color: ShaderStudio::LIME
          end
        end
      end
    end

    def forge_bottom
      row spacing: 14 do
        rectangle width: 920, height: 150, padding: 20, color: ShaderStudio::PANEL,
                  radius: 20, border_color: ShaderStudio::BORDER, border_width: 1 do
          column spacing: 8 do
            row spacing: 8, alignment: :center do
              text "FRAME PACING", size: 15, bold: true, width: 600,
                   color: ShaderStudio::WHITE, wrap: false
              text "POINTER", style: :caption, bold: true, width: 64,
                   color: ShaderStudio::MUTED, wrap: false
              pointer = text state.pointer, id: :pointer_value, bold: true, width: 184,
                             color: ShaderStudio::CYAN, wrap: false
              bind(pointer, :text) { state.pointer }
            end
            chart = line_chart state.frame_times, id: :frame_chart, width: 878, height: 74,
                               color: ShaderStudio::LIME, fill_color: "#22b8ff68",
                               grid_color: "#29213c", line_width: 2, minimum: 12, maximum: 20,
                               show_grid: true, show_points: false
            bind(chart, :values) { state.frame_times }
          end
        end
        rectangle width: 458, height: 150, padding: 14, color: ShaderStudio::PANEL,
                  radius: 20, border_color: ShaderStudio::BORDER, border_width: 1 do
          column spacing: 10 do
            text "PIPELINE HEALTH", size: 15, bold: true, color: ShaderStudio::WHITE, wrap: false
            row spacing: 16 do
              radial_gauge [], value: 96, minimum: 0, maximum: 100, width: 112, height: 98,
                           color: ShaderStudio::CYAN, track_color: "#21303b", thickness: 8,
                           label: "GPU", label_format: "%{value}%"
              radial_gauge [], value: 83, minimum: 0, maximum: 100, width: 112, height: 98,
                           color: ShaderStudio::MAGENTA, track_color: "#38213a", thickness: 8,
                           label: "CACHE", label_format: "%{value}%"
              column spacing: 5, width: 150 do
                text "COMPILE", style: :caption, color: ShaderStudio::MUTED, wrap: false
                text "4.20 ms", bold: true, color: ShaderStudio::LIME, wrap: false
                text "VULKAN / RHI", style: :caption, color: ShaderStudio::MUTED, wrap: false
              end
            end
          end
        end
      end
    end

    def shader_studio_screen
      column spacing: 14 do
        forge_header
        row spacing: 14, alignment: :start do
          forge_viewport
          forge_controls
        end
        forge_bottom
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :shader, "golden_apollian"
      state :frequency, 3.2
      state :amplitude, 0.05
      state :amount, 12.0
      state :intensity, 0.8
      state :radius, 0.28
      state :pointer, "—"
      state :mouse_x, 445.0
      state :mouse_y, 240.0
      state :notice, false
      state :frame_times, [16.2, 16.8, 15.9, 16.4, 16.1, 17.0, 16.3, 15.8, 16.5, 16.1, 16.4, 16.0]

      app :main, title: "Lumen Forge · Shader Studio", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        shader_studio_screen
        saved = alert_dialog "Preset exported", "Aurora field saved to your local library",
                             id: :preset_dialog, severity: :success, opened: false, centered: true,
                             standard_buttons: [:ok], width: 470, height: 300,
                             informative_text: "Shader, uniforms, palette, and frame settings captured.",
                             background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                             foreground: WHITE, muted: MUTED, accent: LIME, button_accent: LIME,
                             border_color: BORDER
        bind(saved, :opened) { state.notice }
        on(saved, :accept) { state.notice = false }
        on(saved, :close) { state.notice = false }
      end

      every(1.0) do
        sample = 15.8 + ((state.frame_times.length + state.pointer.length) % 9) / 10.0
        state.frame_times = state.frame_times.drop(1) + [sample]
      end
    end
  end

  def self.run = build.run
end
