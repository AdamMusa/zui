# frozen_string_literal: true

require "zui"

module CinematicMusicStudio
  INK = "#05050b"
  PANEL = "#0d0c17"
  PANEL_ALT = "#141126"
  BORDER = "#30264a"
  WHITE = "#faf6ff"
  MUTED = "#9085aa"
  PINK = "#ff6eb4"
  VIOLET = "#9c78ff"
  CYAN = "#65e7ff"
  GOLD = "#ffb86b"
  MINT = "#72f2bc"

  TRACKS = [
    {
      id: "residuals", label: "Residuals", artist: "Chris Brown", album: "11:11 (Deluxe)",
      description: "00:30 · Chris Brown · 11:11 (Deluxe)", duration: 30,
      source: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/37/2f/81/372f81ba-acf6-8bb7-57a2-d5308d51620f/mzaf_8185643471338514157.plus.aac.p.m4a",
      artwork: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/2d/5c/c1/2d5cc1a6-86ce-ee16-5985-807f2fffa3cb/196871957267.jpg/600x600bb.jpg",
      store_url: "https://music.apple.com/us/album/residuals/1740205873?i=1740206493&uo=4"
    },
    {
      id: "yo", label: "Yo (Excuse Me Miss)", artist: "Chris Brown", album: "Chris Brown",
      description: "00:30 · Chris Brown · Chris Brown", duration: 30,
      source: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/9f/5c/b4/9f5cb46f-cb5d-7fc9-4123-595c4f2c5217/mzaf_3008420345524030514.plus.aac.p.m4a",
      artwork: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/a6/2f/a7/a62fa746-9e76-0789-76b6-919019807d8a/828768451052.jpg/600x600bb.jpg",
      store_url: "https://music.apple.com/us/album/yo-excuse-me-miss/323098604?i=323098607&uo=4"
    },
    {
      id: "no_air", label: "No Air", artist: "Jordin Sparks & Chris Brown", album: "Jordin Sparks",
      description: "00:30 · Jordin Sparks & Chris Brown", duration: 30,
      source: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/b0/0d/a8/b00da882-00d6-8245-1b4e-904b33a97c9f/mzaf_10468526691358608513.plus.aac.p.m4a",
      artwork: "https://is1-ssl.mzstatic.com/image/thumb/Features125/v4/1b/3d/3b/1b3d3bd6-f283-320f-a152-bbdaf0b4c266/dj.diybuhfk.jpg/600x600bb.jpg",
      store_url: "https://music.apple.com/us/album/no-air/268314568?i=268314585&uo=4"
    },
    {
      id: "forever", label: "Forever", artist: "Chris Brown", album: "Forever",
      description: "00:30 · Chris Brown · Forever", duration: 30,
      source: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/cd/78/7c/cd787c70-dad4-dab2-e8fe-aea191034f9c/mzaf_17742789422087580915.plus.aac.p.m4a",
      artwork: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/f3/50/06/f350068c-43f2-4510-a3b0-86458da63606/888880600059.jpg/600x600bb.jpg",
      store_url: "https://music.apple.com/us/album/forever-main-version/282988493?i=282988494&uo=4"
    }
  ].freeze

  module UI
    def music_item_value(item, key)
      item[key] || item[key.to_s]
    end

    def select_music_track(index)
      queue = state.queue
      return if queue.empty?

      track = queue[index % queue.length]
      transaction do
        state.track_id = music_item_value(track, :id)
        state.track = music_item_value(track, :label)
        state.duration = music_item_value(track, :duration).to_i
        state.position = 0
        state.seek_revision = state.seek_revision + 1
        state.playing = true
      end
    end

    def current_music_track
      state.queue.find { |item| music_item_value(item, :id) == state.track_id } || state.queue.first
    end

    def current_music_source
      music_item_value(current_music_track, :source).to_s
    end

    def current_music_value(key)
      music_item_value(current_music_track, key).to_s
    end

    def step_music_track(direction)
      index = state.queue.index { |item| music_item_value(item, :id) == state.track_id } || 0
      select_music_track(index + direction)
    end

    def music_header
      rectangle width: 1392, height: 74, padding: 14, color: CinematicMusicStudio::PANEL,
                radius: 20, border_color: CinematicMusicStudio::BORDER, border_width: 1 do
        row spacing: 14, alignment: :center do
          gradient colors: [CinematicMusicStudio::PINK, CinematicMusicStudio::VIOLET,
                            CinematicMusicStudio::CYAN], type: :conical,
                   width: 44, height: 44, radius: 14
          column spacing: 1, width: 340 do
            text "NOCTURNE", size: 19, bold: true, color: CinematicMusicStudio::WHITE, wrap: false
            text "SPATIAL MUSIC / MASTERING ROOM", style: :caption,
                 color: CinematicMusicStudio::MUTED, wrap: false
          end
          spacer width: 600
          chip "LOSSLESS 96K", icon: :music, selected: true, background: "#20182e",
                               selected_background: "#20182e", foreground: CinematicMusicStudio::CYAN,
                               selected_foreground: CinematicMusicStudio::CYAN, accent: CinematicMusicStudio::CYAN
          column spacing: 1, width: 150 do
            text "OUTPUT", style: :caption, color: CinematicMusicStudio::MUTED, wrap: false
            text "Studio Monitors", bold: true, color: CinematicMusicStudio::WHITE, wrap: false
          end
          badge "ATMOS", size: 30, background: "#281b3b", foreground: CinematicMusicStudio::PINK
        end
      end
    end

    def album_stage
      stack do
        cover = image current_music_value(:artwork), id: :album_cover,
                      width: 386, height: 470, fill_mode: :preserve_aspect_crop,
                      asynchronous: true, cache: false, retain_while_loading: true
        bind(cover, :source) { current_music_value(:artwork) }
        particle_system id: :album_particles, width: 386, height: 470,
                        emit_rate: 7, life_span: 2200, maximum_emitted: 25,
                        size: 4, end_size: 1, size_variation: 3,
                        color: CinematicMusicStudio::PINK, alpha: 0.28,
                        emitter_x: 20, emitter_y: 370, emitter_width: 340, emitter_height: 60,
                        velocity_angle: 270, velocity: 12, velocity_angle_variation: 28,
                        turbulence: 8, turbulence_width: 386, turbulence_height: 470
        rectangle width: 386, height: 470, padding: 16, color: "transparent", radius: 22,
                  border_color: CinematicMusicStudio::BORDER, border_width: 1 do
          column spacing: 352 do
            badge "30-SECOND PREVIEW", size: 23, background: "#26172d", foreground: CinematicMusicStudio::PINK,
                  font_size: 9
            column spacing: 2 do
              title = text state.track, id: :track_title, size: 20, bold: true,
                           color: CinematicMusicStudio::WHITE, width: 350, wrap: false
              bind(title, :text) { state.track }
              artist = text current_music_value(:artist), id: :track_artist,
                            color: "#d7cdec", width: 350, wrap: false
              bind(artist, :text) { current_music_value(:artist) }
              album = text current_music_value(:album), id: :track_album, style: :caption,
                           color: CinematicMusicStudio::MUTED, width: 350, wrap: false
              bind(album, :text) { current_music_value(:album) }
            end
          end
        end
      end
    end

    def music_wave_stage
      rectangle width: 650, height: 470, padding: 15, color: CinematicMusicStudio::PANEL,
                radius: 20, border_color: CinematicMusicStudio::BORDER, border_width: 1 do
        column spacing: 9 do
          row spacing: 8, alignment: :center do
            column spacing: 1, width: 430 do
              text "SPATIAL WAVEFORM", size: 15, bold: true,
                   color: CinematicMusicStudio::WHITE, wrap: false
              text "Object bed · 24 channels", style: :caption,
                   color: CinematicMusicStudio::MUTED, wrap: false
            end
            status = chip(state.playing ? "PLAYING" : "PAUSED", id: :play_status,
                          icon: state.playing ? :play : :pause, selected: true,
                          background: "#24182d", selected_background: "#24182d",
                          foreground: CinematicMusicStudio::PINK,
                          selected_foreground: CinematicMusicStudio::PINK,
                          accent: CinematicMusicStudio::PINK)
            bind(status, :text) { state.playing ? "PLAYING" : "PAUSED" }
            bind(status, :icon) { state.playing ? "play" : "pause" }
          end

          music_shader = shader_effect nil, id: :music_shader, shader: :wave, width: 618, height: 230,
                                       running: state.playing, fps: 60,
                                       frequency: 2.4, amplitude: 0.025 do
            gradient colors: ["#120d24", CinematicMusicStudio::VIOLET, CinematicMusicStudio::PINK,
                              CinematicMusicStudio::GOLD, CinematicMusicStudio::CYAN, "#120d24"],
                     stops: [0.0, 0.18, 0.38, 0.58, 0.78, 1.0],
                     width: 618, height: 230, start_x: 0, end_x: 618, radius: 18
          end
          bind(music_shader, :running) { state.playing }

          position = slider state.position, id: :track_progress, minimum: 0, maximum: state.duration,
                            step: 1, width: 618, track_height: 7, knob_size: 14,
                            track_color: "#2b233b", fill_color: CinematicMusicStudio::PINK,
                            knob_color: CinematicMusicStudio::WHITE do |event|
            transaction do
              state.position = event.fetch("value", state.position).to_f.round(2)
              state.seek_revision = state.seek_revision + 1
            end
          end
          bind(position, :value) { state.position }
          bind(position, :maximum) { state.duration }
          row spacing: 8, alignment: :center do
            elapsed = text format_music_time(state.position), id: :elapsed_time,
                           style: :caption, color: CinematicMusicStudio::MUTED, width: 80, wrap: false
            bind(elapsed, :text) { format_music_time(state.position) }
            spacer width: 458
            duration = text format_music_time(state.duration), id: :track_duration,
                            style: :caption, color: CinematicMusicStudio::MUTED, wrap: false
            bind(duration, :text) { format_music_time(state.duration) }
          end

          row spacing: 13, alignment: :center do
            spacer width: 156
            round_button "", id: :previous_track, icon: :arrow_left, diameter: 44,
                         foreground: CinematicMusicStudio::WHITE, background: "#1a1625",
                         accent: CinematicMusicStudio::PINK do
              step_music_track(-1)
            end
            play = round_button "", id: :play_toggle, icon: state.playing ? :pause : :play,
                                diameter: 62, checked: state.playing, checkable: true,
                                foreground: CinematicMusicStudio::INK,
                                background: CinematicMusicStudio::WHITE,
                                checked_background: CinematicMusicStudio::PINK,
                                accent: CinematicMusicStudio::PINK do
              state.playing = !state.playing
            end
            bind(play, :icon) { state.playing ? "pause" : "play" }
            bind(play, :checked) { state.playing }
            round_button "", id: :next_track, icon: :arrow_right, diameter: 44,
                         foreground: CinematicMusicStudio::WHITE, background: "#1a1625",
                         accent: CinematicMusicStudio::PINK do
              step_music_track(1)
            end
            button "Master", id: :master_track, icon: :save, bordered: true,
                   foreground: CinematicMusicStudio::CYAN, background: "transparent",
                   accent: CinematicMusicStudio::CYAN do
              state.master_dialog = true
            end
          end
          row spacing: 10, alignment: :center do
            text "Preview provided courtesy of iTunes", style: :caption,
                 color: CinematicMusicStudio::MUTED, width: 390, wrap: false
            store = button "OPEN IN APPLE MUSIC", id: :open_apple_music, icon: :apple,
                           url: current_music_value(:store_url), bordered: true,
                           foreground: CinematicMusicStudio::CYAN, background: "#141126",
                           accent: CinematicMusicStudio::CYAN, font_size: 10
            bind(store, :url) { current_music_value(:store_url) }
          end
        end
      end
    end

    def format_music_time(seconds)
      minutes = seconds.to_i / 60
      remainder = seconds.to_i % 60
      format("%02d:%02d", minutes, remainder)
    end

    def mixer_strip(label, state_name, color)
      column spacing: 5 do
        row spacing: 8, alignment: :center do
          text label, style: :caption, bold: true, width: 230,
               color: CinematicMusicStudio::MUTED, wrap: false
          value = text "#{(state.public_send(state_name) * 100).to_i}%", id: "#{state_name}.value",
                       bold: true, color: color, wrap: false
          bind(value, :text) { "#{(state.public_send(state_name) * 100).to_i}%" }
        end
        control = slider state.public_send(state_name), id: "#{state_name}.slider",
                         minimum: 0, maximum: 1, step: 0.01, width: 320,
                         track_color: "#2b233b", fill_color: color,
                         knob_color: CinematicMusicStudio::WHITE, track_height: 6, knob_size: 17 do |event|
          state.public_send("#{state_name}=", event.fetch("value", 0).to_f)
        end
        bind(control, :value) { state.public_send(state_name) }
      end
    end

    def music_mixer
      rectangle width: 328, height: 470, padding: 15, color: CinematicMusicStudio::PANEL_ALT,
                radius: 20, border_color: CinematicMusicStudio::BORDER, border_width: 1 do
        column spacing: 13 do
          text "MIXER", size: 15, bold: true, color: CinematicMusicStudio::WHITE, wrap: false
          mixer_strip "MASTER", :volume, CinematicMusicStudio::PINK
          mixer_strip "SPATIAL WIDTH", :spatial, CinematicMusicStudio::CYAN
          mixer_strip "ROOM", :room, CinematicMusicStudio::VIOLET
          divider length: 296, color: CinematicMusicStudio::BORDER
          text "SIGNAL CHAIN", style: :caption, bold: true,
               color: CinematicMusicStudio::MUTED, wrap: false
          [["Analog warmth", :warmth, CinematicMusicStudio::GOLD],
           ["Binaural render", :binaural, CinematicMusicStudio::CYAN]].each do |label, key, color|
            row spacing: 8, alignment: :center do
              text label, bold: true, width: 235, color: CinematicMusicStudio::WHITE, wrap: false
              control = toggle_switch id: "#{key}.switch", checked: state.public_send(key),
                                      rounded: true, cursor_ring: false, track_width: 44,
                                      track_height: 24, knob_size: 18, knob_inset: 3,
                                      foreground: CinematicMusicStudio::WHITE, accent: color do |event|
                state.public_send("#{key}=", event.fetch("value", false) == true)
              end
              bind(control, :checked) { state.public_send(key) }
            end
          end
          rectangle width: 296, height: 90, padding: 11, color: "#171327",
                    radius: 14, border_color: CinematicMusicStudio::BORDER, border_width: 1 do
            column spacing: 4 do
              text "HEADROOM", style: :caption, color: CinematicMusicStudio::MUTED, wrap: false
              text "−8.4 dB", size: 22, bold: true, color: CinematicMusicStudio::MINT, wrap: false
              text "True peak −1.0 dBTP", style: :caption,
                   color: CinematicMusicStudio::MUTED, wrap: false
            end
          end
        end
      end
    end

    def music_bottom
      row spacing: 14 do
        rectangle width: 680, height: 250, padding: 14, color: CinematicMusicStudio::PANEL,
                  radius: 20, border_color: CinematicMusicStudio::BORDER, border_width: 1 do
          column spacing: 8 do
            row spacing: 8, alignment: :center do
              text "UP NEXT", size: 15, bold: true, width: 470,
                   color: CinematicMusicStudio::WHITE, wrap: false
              text "Drag to reorder", style: :caption, color: CinematicMusicStudio::MUTED, wrap: false
            end
            queue = reorderable_list state.queue, id: :track_queue, key_field: :id,
                                     label_field: :label, description_field: :description,
                                     selected: state.track_id, width: 650, height: 185,
                                     spacing: 6, padding: 4, item_padding: 13, item_height: 58,
                                     handle_position: :right, drag_enabled: true,
                                     drag_scale: 1.025, drag_opacity: 0.95, drag_transition_duration: 190,
                                     background: "transparent", item_background: "#110f1b",
                                     selected_background: "#271833", foreground: CinematicMusicStudio::WHITE,
                                     selected_foreground: CinematicMusicStudio::PINK,
                                     muted: CinematicMusicStudio::MUTED,
                                     border_color: CinematicMusicStudio::BORDER, radius: 12, font_size: 12
            bind(queue, :items) { state.queue }
            on(queue, :activate) do |event|
              item = event.fetch("item", {})
              state.track_id = item.fetch("id", state.track_id)
              state.track = item.fetch("label", state.track)
              selected = state.queue.find { |track| music_item_value(track, :id) == state.track_id }
              transaction do
                state.duration = music_item_value(selected, :duration).to_i if selected
                state.position = 0
                state.seek_revision = state.seek_revision + 1
                state.playing = true
              end
            end
            on(queue, :reorder) do |event|
              from = event.fetch("from", 0).to_i
              to = event.fetch("to", 0).to_i
              updated = state.queue.dup
              moved = updated.delete_at(from)
              updated.insert(to, moved) if moved
              state.queue = updated
            end
          end
        end

        rectangle width: 698, height: 250, padding: 14, color: CinematicMusicStudio::PANEL,
                  radius: 20, border_color: CinematicMusicStudio::BORDER, border_width: 1 do
          column spacing: 8 do
            row spacing: 8, alignment: :center do
              text "FREQUENCY FIELD", size: 15, bold: true, width: 470,
                   color: CinematicMusicStudio::WHITE, wrap: false
              badge "RMS −14.2", size: 23, background: "#20182e", foreground: CinematicMusicStudio::CYAN,
                    font_size: 9
            end
            spectrum = bar_chart state.spectrum, id: :spectrum_chart,
                                 labels: %w[32 64 125 250 500 1K 2K 4K 8K 16K],
                                 colors: [CinematicMusicStudio::VIOLET, CinematicMusicStudio::PINK,
                                          CinematicMusicStudio::GOLD, CinematicMusicStudio::CYAN],
                                 width: 668, height: 166, grid_color: "#2a2340",
                                 minimum: 0, maximum: 100, show_grid: true, bar_spacing: 8
            bind(spectrum, :values) { state.spectrum }
            row spacing: 24 do
              text "LOW  +1.2 dB", style: :caption, bold: true, color: CinematicMusicStudio::VIOLET, wrap: false
              text "MID  −0.4 dB", style: :caption, bold: true, color: CinematicMusicStudio::PINK, wrap: false
              text "AIR  +2.1 dB", style: :caption, bold: true, color: CinematicMusicStudio::CYAN, wrap: false
            end
          end
        end
      end
    end

    def music_studio_screen
      column spacing: 14 do
        music_header
        row spacing: 14, alignment: :start do
          album_stage
          music_wave_stage
          music_mixer
        end
        music_bottom
      end
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :playing, true
      state :position, 0.0
      state :track, TRACKS.first.fetch(:label)
      state :track_id, TRACKS.first.fetch(:id)
      state :duration, TRACKS.first.fetch(:duration)
      state :seek_revision, 0
      state :audio_ready, false
      state :audio_error, ""
      state :volume, 0.78
      state :spatial, 0.86
      state :room, 0.32
      state :warmth, true
      state :binaural, true
      state :master_dialog, false
      state :queue, TRACKS
      state :spectrum, [42, 58, 73, 64, 81, 69, 77, 61, 48, 32]

      app :main, title: "Nocturne · Spatial Music Studio", width: 1440, height: 900,
                 min_width: 1280, min_height: 780, color: INK do
        player = audio current_music_source, id: :music_player, auto_play: false,
                       playback: state.playing ? :play : :pause,
                       position: (state.position * 1000).round,
                       seek_revision: state.seek_revision, volume: state.volume,
                       muted: false, loops: 1, playback_rate: 1.0
        bind(player, :source) { current_music_source }
        bind(player, :playback) { state.playing ? "play" : "pause" }
        bind(player, :position) { (state.position * 1000).round }
        bind(player, :seek_revision) { state.seek_revision }
        bind(player, :volume) { state.volume }
        on(player, :position) do |event|
          state.position = (event.fetch("value", 0).to_f / 1000).round(2)
        end
        on(player, :duration) do |event|
          duration = (event.fetch("value", 0).to_f / 1000).round
          state.duration = duration if duration.positive?
        end
        on(player, :loaded) do |event|
          transaction do
            state.audio_ready = true
            state.audio_error = ""
            duration = (event.fetch("duration", 0).to_f / 1000).round
            state.duration = duration if duration.positive?
          end
        end
        on(player, :error) do |event|
          transaction do
            state.audio_ready = false
            state.audio_error = event.fetch("message", "Playback failed").to_s
            state.playing = false
          end
        end
        on(player, :end) { step_music_track(1) }
        on(player, :play) { state.playing = true }
        on(player, :pause) { state.playing = false }
        music_studio_screen
        master = alert_dialog "Spatial master captured", "#{TRACKS.first.fetch(:label)} is ready for review",
                              id: :master_dialog, severity: :success, opened: false,
                              centered: true, standard_buttons: [:ok], width: 480, height: 420,
                              image: "assets/nocturne-cover.svg", image_height: 170,
                              image_fill_mode: :preserve_aspect_fit,
                              informative_text: "96 kHz · 24-bit · integrated loudness −14.2 LUFS",
                              background: PANEL, header_background: PANEL_ALT, footer_background: PANEL_ALT,
                              foreground: WHITE, muted: MUTED, accent: PINK,
                              button_accent: PINK, border_color: BORDER
        bind(master, :opened) { state.master_dialog }
        bind(master, :message) { "#{state.track} is ready for review" }
        on(master, :accept) { state.master_dialog = false }
        on(master, :close) { state.master_dialog = false }
      end

      every(0.5) do
        if state.playing
          shift = state.position.to_i % state.spectrum.length
          transaction do
            state.spectrum = state.spectrum.each_with_index.map { |value, index| 30 + ((value + shift * (index + 2)) % 62) }
          end
        end
      end
    end
  end

  def self.run = build.run
end
