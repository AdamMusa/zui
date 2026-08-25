# frozen_string_literal: true

require "zui"

module AvatarRunner
  WIDTH = 960
  HEIGHT = 430
  GROUND_Y = 342
  PLAYER_X = 112
  PLAYER_WIDTH = 44
  PLAYER_HEIGHT = 58
  PLAYER_GROUND_Y = GROUND_Y - PLAYER_HEIGHT
  GRAVITY = 1.05
  JUMP_VELOCITY = -15.8
  STARTING_SPEED = 7.2

  INK = "#060811"
  PANEL = "#0d1220"
  PANEL_ALT = "#121a2b"
  BORDER = "#26324a"
  WHITE = "#f4f7ff"
  MUTED = "#8792aa"
  CYAN = "#42e8ff"
  LIME = "#a8ff60"
  VIOLET = "#a77bff"
  ROSE = "#ff5c8a"
  GOLD = "#ffd166"

  STARS = [
    [42, 48, 2], [118, 82, 1], [196, 36, 1], [274, 104, 2], [356, 58, 1],
    [438, 26, 2], [524, 96, 1], [612, 45, 1], [704, 78, 2], [788, 30, 1],
    [856, 112, 1], [928, 62, 2]
  ].freeze

  BUILDINGS = [
    [18, 92, 42], [88, 128, 54], [176, 76, 38], [246, 116, 48], [332, 88, 42],
    [410, 142, 58], [506, 96, 44], [588, 124, 52], [682, 82, 40], [754, 136, 56],
    [846, 104, 46], [926, 74, 36]
  ].freeze

  module UI
    def runner_restart
      transaction do
        state.phase = "running"
        state.frame = 0
        state.score = 0
        state.player_y = AvatarRunner::PLAYER_GROUND_Y.to_f
        state.velocity = 0.0
        state.obstacle_x = 830.0
        state.obstacle_height = 58
        state.speed = AvatarRunner::STARTING_SPEED
        state.ground_offset = 0.0
      end
    end

    def runner_jump
      runner_restart unless state.phase == "running"
      return unless state.player_y >= AvatarRunner::PLAYER_GROUND_Y - 1

      state.velocity = AvatarRunner::JUMP_VELOCITY
    end

    def runner_toggle_pause
      return if state.phase == "over" || state.phase == "ready"

      state.phase = state.phase == "paused" ? "running" : "paused"
    end

    def runner_action_label
      return "Restart run" if state.phase == "over"
      return "Resume" if state.phase == "paused"
      return "Jump" if state.phase == "running"

      "Start run"
    end

    def runner_status
      {
        "ready" => "READY",
        "running" => "RUNNING",
        "paused" => "PAUSED",
        "over" => "SIGNAL LOST"
      }.fetch(state.phase)
    end

    def runner_step
      return unless state.phase == "running"

      next_velocity = state.velocity.to_f + AvatarRunner::GRAVITY
      next_y = state.player_y.to_f + next_velocity
      if next_y >= AvatarRunner::PLAYER_GROUND_Y
        next_y = AvatarRunner::PLAYER_GROUND_Y.to_f
        next_velocity = 0.0
      end

      next_obstacle_x = state.obstacle_x.to_f - state.speed.to_f
      next_score = state.score.to_i
      next_speed = state.speed.to_f
      next_height = state.obstacle_height.to_i

      if next_obstacle_x < -52
        next_score += 1
        next_obstacle_x = AvatarRunner::WIDTH + 110 + ((next_score * 73) % 190)
        next_height = 44 + ((next_score * 17) % 48)
        next_speed = [AvatarRunner::STARTING_SPEED + next_score * 0.28, 13.5].min
      end

      player_left = AvatarRunner::PLAYER_X + 7
      player_right = AvatarRunner::PLAYER_X + AvatarRunner::PLAYER_WIDTH - 5
      player_top = next_y + 5
      player_bottom = next_y + AvatarRunner::PLAYER_HEIGHT - 3
      obstacle_left = next_obstacle_x + 4
      obstacle_right = next_obstacle_x + 42
      obstacle_top = AvatarRunner::GROUND_Y - next_height + 5
      collided = player_right > obstacle_left && player_left < obstacle_right &&
        player_bottom > obstacle_top && player_top < AvatarRunner::GROUND_Y

      transaction do
        state.frame += 1
        state.player_y = next_y.round(2)
        state.velocity = next_velocity.round(2)
        state.obstacle_x = next_obstacle_x.round(2)
        state.obstacle_height = next_height
        state.score = next_score
        state.speed = next_speed.round(2)
        state.ground_offset = (state.ground_offset.to_f + next_speed) % 96
        if collided
          state.phase = "over"
          state.best = [state.best.to_i, next_score].max
        end
      end
    end

    def runner_rect(commands, x:, y:, width:, height:, color:, radius: 0, stroke: nil, line_width: 1)
      if radius.to_f.positive?
        commands << { op: "begin_path", fill_style: color, stroke_style: stroke, line_width: line_width }
        commands << { op: "rounded_rect", x: x, y: y, width: width, height: height, radius: radius }
        commands << { op: "fill" }
        commands << { op: "stroke" } if stroke
      else
        commands << { op: "fill_rect", x: x, y: y, width: width, height: height, fill_style: color }
        commands << { op: "stroke_rect", x: x, y: y, width: width, height: height,
                      stroke_style: stroke, line_width: line_width } if stroke
      end
    end

    def runner_text(commands, text, x:, y:, color:, font:, align: "left")
      commands << { op: "fill_text", text: text, x: x, y: y, fill_style: color,
                    font: font, text_align: align, text_baseline: "alphabetic" }
    end

    def runner_commands
      commands = [
        {
          op: "fill_rect", x: 0, y: 0, width: AvatarRunner::WIDTH, height: AvatarRunner::HEIGHT,
          fill_style: {
            type: "linear", x0: 0, y0: 0, x1: 0, y1: AvatarRunner::HEIGHT,
            stops: [[0, "#070a18"], [0.58, "#11183a"], [1, "#171128"]]
          }
        }
      ]

      star_shift = state.ground_offset.to_f * 0.12
      AvatarRunner::STARS.each_with_index do |(base_x, y, size), index|
        x = (base_x - star_shift + AvatarRunner::WIDTH) % AvatarRunner::WIDTH
        color = index.even? ? "rgba(66, 232, 255, 0.68)" : "rgba(167, 123, 255, 0.68)"
        commands << { op: "fill_rect", x: x.round(1), y: y, width: size, height: size,
                      fill_style: color }
      end

      skyline_shift = state.ground_offset.to_f * 0.42
      AvatarRunner::BUILDINGS.each_with_index do |(base_x, height, width), index|
        x = ((base_x - skyline_shift + AvatarRunner::WIDTH + 80) % (AvatarRunner::WIDTH + 80)) - 40
        y = AvatarRunner::GROUND_Y - height
        runner_rect(commands, x: x.round(1), y: y, width: width, height: height,
                    color: index.even? ? "#111a32" : "#151c38")
        2.times do |window|
          commands << { op: "fill_rect", x: (x + 9 + window * 15).round(1), y: y + 18,
                        width: 5, height: 9,
                        fill_style: window.zero? ? "rgba(42, 112, 136, 0.62)" : "rgba(85, 60, 130, 0.62)" }
        end
      end

      commands << { op: "fill_rect", x: 0, y: AvatarRunner::GROUND_Y, width: AvatarRunner::WIDTH,
                    height: AvatarRunner::HEIGHT - AvatarRunner::GROUND_Y, fill_style: "#090d18" }
      commands << { op: "fill_rect", x: 0, y: AvatarRunner::GROUND_Y, width: AvatarRunner::WIDTH,
                    height: 3, fill_style: "rgba(66, 232, 255, 0.82)" }

      12.times do |index|
        x = index * 96 - state.ground_offset.to_f
        commands << { op: "begin_path", stroke_style: index.even? ? "#1f3552" : "#2d244e", line_width: 2 }
        commands << { op: "move_to", x: x.round(1), y: AvatarRunner::HEIGHT }
        commands << { op: "line_to", x: (x + 42).round(1), y: AvatarRunner::GROUND_Y }
        commands << { op: "stroke" }
      end

      obstacle_x = state.obstacle_x.to_f
      obstacle_height = state.obstacle_height.to_i
      obstacle_y = AvatarRunner::GROUND_Y - obstacle_height
      runner_rect(commands, x: obstacle_x, y: obstacle_y, width: 46, height: obstacle_height,
                  color: "#271731", radius: 8, stroke: AvatarRunner::ROSE, line_width: 2)
      commands << { op: "fill_rect", x: obstacle_x + 9, y: obstacle_y + 12,
                    width: 28, height: 5, fill_style: AvatarRunner::ROSE }
      commands << { op: "fill_rect", x: obstacle_x + 9, y: obstacle_y + 25,
                    width: 17, height: 4, fill_style: "rgba(255, 209, 102, 0.78)" }
      runner_text(commands, "!", x: obstacle_x + 23, y: obstacle_y - 9,
                  color: AvatarRunner::ROSE, font: "bold 16px sans-serif", align: "center")

      player_y = state.player_y.to_f
      running_phase = state.frame.to_i % 6 < 3
      commands << { op: "fill_rect", x: AvatarRunner::PLAYER_X - 18, y: AvatarRunner::GROUND_Y + 8,
                    width: 80, height: 7, fill_style: "rgba(2, 4, 10, 0.52)" }
      if state.phase == "running"
        3.times do |trail|
          commands << { op: "fill_rect", x: AvatarRunner::PLAYER_X - 18 - trail * 15,
                        y: player_y + 30 + trail * 4, width: 20 - trail * 4, height: 3,
                        fill_style: "rgba(66, 232, 255, #{0.58 - trail * 0.12})" }
        end
      end

      leg_left = running_phase ? 5 : 22
      leg_right = running_phase ? 24 : 8
      runner_rect(commands, x: AvatarRunner::PLAYER_X + leg_left, y: player_y + 43,
                  width: 10, height: 15, color: "#34255d", radius: 4)
      runner_rect(commands, x: AvatarRunner::PLAYER_X + leg_right, y: player_y + 43,
                  width: 10, height: 15, color: "#493675", radius: 4)
      runner_rect(commands, x: AvatarRunner::PLAYER_X + 5, y: player_y + 18,
                  width: 34, height: 31, color: "#222f55", radius: 10,
                  stroke: AvatarRunner::VIOLET, line_width: 2)
      runner_rect(commands, x: AvatarRunner::PLAYER_X, y: player_y,
                  width: AvatarRunner::PLAYER_WIDTH, height: 25, color: "#14243f", radius: 9,
                  stroke: AvatarRunner::CYAN, line_width: 2)
      commands << { op: "fill_rect", x: AvatarRunner::PLAYER_X + 8, y: player_y + 9,
                    width: 28, height: 7, fill_style: "#07111e" }
      commands << { op: "fill_rect", x: AvatarRunner::PLAYER_X + 28, y: player_y + 11,
                    width: 4, height: 3, fill_style: AvatarRunner::LIME }
      commands << { op: "fill_rect", x: AvatarRunner::PLAYER_X + 36, y: player_y + 11,
                    width: 4, height: 3, fill_style: AvatarRunner::CYAN }
      runner_rect(commands, x: AvatarRunner::PLAYER_X + 13, y: player_y + 26,
                  width: 18, height: 9, color: AvatarRunner::CYAN, radius: 4)

      runner_text(commands, format("%03d", state.score), x: AvatarRunner::WIDTH - 30, y: 42,
                  color: AvatarRunner::WHITE, font: "bold 24px monospace", align: "right")
      runner_text(commands, "SECTOR SCORE", x: AvatarRunner::WIDTH - 30, y: 61,
                  color: AvatarRunner::MUTED, font: "10px monospace", align: "right")

      if state.phase != "running"
        commands << { op: "fill_rect", x: 0, y: 0, width: AvatarRunner::WIDTH,
                      height: AvatarRunner::HEIGHT, fill_style: "rgba(5, 7, 16, 0.72)" }
        title = state.phase == "over" ? "RUN INTERRUPTED" : state.phase == "paused" ? "RUN PAUSED" : "AVATAR READY"
        subtitle = state.phase == "over" ? "Press Enter or R to restart" : "Press Space, Up, or click to jump"
        runner_text(commands, title, x: AvatarRunner::WIDTH / 2, y: 174,
                    color: state.phase == "over" ? AvatarRunner::ROSE : AvatarRunner::CYAN,
                    font: "bold 30px sans-serif", align: "center")
        runner_text(commands, subtitle, x: AvatarRunner::WIDTH / 2, y: 208,
                    color: AvatarRunner::WHITE, font: "15px sans-serif", align: "center")
        runner_text(commands, "BEST  #{format('%03d', state.best)}", x: AvatarRunner::WIDTH / 2, y: 240,
                    color: AvatarRunner::LIME, font: "bold 12px monospace", align: "center")
      end

      commands
    end

    def runner_header
      rectangle width: 1040, height: 76, padding: 14, color: AvatarRunner::PANEL,
                radius: 20, border_color: AvatarRunner::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          rectangle width: 46, height: 46, radius: 15, color: "#122b3a",
                    border_color: AvatarRunner::CYAN, border_width: 1 do
            icon :play, size: 18, color: AvatarRunner::CYAN
          end
          column spacing: 1, width: 520 do
            text "AVATAR RUNNER", size: 19, bold: true, color: AvatarRunner::WHITE, wrap: false
            text "NATIVE RUBY ARCADE SAMPLE", style: :caption, color: AvatarRunner::MUTED, wrap: false
          end
          spacer width: 162
          column spacing: 1, width: 100 do
            text "BEST", style: :caption, color: AvatarRunner::MUTED, wrap: false
            best = text format("%03d", state.best), id: :best_score, bold: true,
                        color: AvatarRunner::LIME, wrap: false
            bind(best, :text) { format("%03d", state.best) }
          end
          status = badge runner_status, id: :runner_status, size: 30,
                         background: "#152339", foreground: AvatarRunner::CYAN
          bind(status, :value) { runner_status }
          bind(status, :foreground) { state.phase == "over" ? AvatarRunner::ROSE : AvatarRunner::CYAN }
        end
      end
    end

    def runner_game
      rectangle width: 1040, height: 478, padding: 20, color: AvatarRunner::PANEL_ALT,
                radius: 22, border_color: AvatarRunner::BORDER, border_width: 1 do
        key_catcher id: :runner_keys, blocked: false do
          scene = canvas runner_commands, id: :game_canvas, width: AvatarRunner::WIDTH,
                         height: AvatarRunner::HEIGHT, background: AvatarRunner::INK,
                         antialiasing: true, smooth: true
          bind(scene, :commands) { runner_commands }
          on(scene, :click) { runner_jump }
          on(:activate) { runner_jump }
          on(:return) { state.phase == "over" ? runner_restart : runner_jump }
          on(:move) { |event| runner_jump if event.fetch("dy", 0).negative? }
          on(:close) { runner_toggle_pause }
          on(:text) { |event| runner_restart if event.fetch("text", "").downcase == "r" }
        end
      end
    end

    def runner_controls
      rectangle width: 1040, height: 78, padding: 13, color: AvatarRunner::PANEL,
                radius: 18, border_color: AvatarRunner::BORDER, border_width: 1 do
        row spacing: 12, alignment: :center do
          action = button runner_action_label, id: :runner_action, icon: :play,
                          foreground: AvatarRunner::WHITE, background: "#1a2942",
                          accent: AvatarRunner::CYAN, bordered: true do
            state.phase == "running" ? runner_jump : runner_restart
          end
          bind(action, :text) { runner_action_label }
          spacer width: 60
          chip "SPACE / ↑", selected: true, background: "#151d31",
                              selected_background: "#152b37", foreground: AvatarRunner::CYAN,
                              selected_foreground: AvatarRunner::CYAN, accent: AvatarRunner::CYAN
          text "jump", style: :caption, color: AvatarRunner::MUTED, width: 68, wrap: false
          chip "ESC", selected: true, background: "#151d31",
                       selected_background: "#251c35", foreground: AvatarRunner::VIOLET,
                       selected_foreground: AvatarRunner::VIOLET, accent: AvatarRunner::VIOLET
          text "pause", style: :caption, color: AvatarRunner::MUTED, width: 72, wrap: false
          chip "R", selected: true, background: "#151d31",
                     selected_background: "#2a2418", foreground: AvatarRunner::GOLD,
                     selected_foreground: AvatarRunner::GOLD, accent: AvatarRunner::GOLD
          text "restart", style: :caption, color: AvatarRunner::MUTED, width: 78, wrap: false
          spacer width: 44
          speed = text "#{state.speed.round(1)} PX/TICK", id: :runner_speed,
                       style: :caption, bold: true, color: AvatarRunner::LIME, wrap: false
          bind(speed, :text) { "#{state.speed.round(1)} PX/TICK" }
        end
      end
    end

    def runner_screen
      rectangle width: 1080, height: 680, padding: 20, color: AvatarRunner::INK do
        column spacing: 14 do
          runner_header
          runner_game
          runner_controls
        end
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :phase, "ready"
      state :frame, 0
      state :score, 0
      state :best, 0
      state :player_y, PLAYER_GROUND_Y.to_f
      state :velocity, 0.0
      state :obstacle_x, 830.0
      state :obstacle_height, 58
      state :speed, STARTING_SPEED
      state :ground_offset, 0.0

      app :main, title: "Avatar Runner · Zui Native Game", width: 1080, height: 680,
                 min_width: 1080, min_height: 680, color: INK do
        runner_screen
      end

      every(1.0 / 30.0) { runner_step }
    end
  end

  def self.run = build.run
end
