# frozen_string_literal: true

require "zui"

module MobileKitchenSink
  BG = "#050b16"
  PANEL = "#0d1b2d"
  PANEL_ALT = "#12243b"
  BORDER = "#24486c"
  WHITE = "#f4fbff"
  MUTED = "#91aac2"
  CYAN = "#55ddff"
  MINT = "#61f2b0"
  GOLD = "#ffd166"
  RED = "#ff6b7d"

  module UI
    def log(message)
      state.log_line = message.to_s
    end

    def bind_command(node, command_state, revision_state)
      bind(node, :command) { state.public_send(command_state) }
      bind(node, :command_revision) { state.public_send(revision_state) }
    end

    def issue(command_state, revision_state, command)
      transaction do
        state.public_send("#{command_state}=", command)
        state.public_send("#{revision_state}=", state.public_send(revision_state) + 1)
      end
    end

    def section_title(icon_name, title, subtitle)
      row spacing: 10, alignment: :center do
        rectangle width: 42, height: 42, radius: 13, color: "#153455" do
          icon icon_name, size: 19, color: CYAN
        end
        column spacing: 1, width: 258 do
          text title, size: 18, bold: true, color: WHITE, wrap: false
          text subtitle, size: 11, color: MUTED, wrap: false
        end
      end
    end

    def hero_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          row spacing: 10, alignment: :center do
            badge "NATIVE", background: "#164657", foreground: CYAN
            badge "KITCHEN SINK", background: "#163f31", foreground: MINT
          end
          text "Trust every mobile layer", size: 27, bold: true, color: WHITE,
               width: 312, wrap: true
          text "Permissions, media, motion, touch, maps, charts, speech, web, files, and keyboard—all from Ruby through native Qt/QML.",
               size: 13, color: MUTED, width: 312, wrap: true
          row spacing: 8 do
            status = chip "READY", id: :runtime_status, selected: true, height: 36,
                          background: "#14362b", selected_background: "#14362b",
                          foreground: MINT, selected_foreground: MINT, accent: MINT
            bind(status, :text) { state.runtime_ready ? "READY" : "CHECKING" }
            text "Live failures appear in Diagnostics", size: 11, color: MUTED,
                 width: 210, wrap: true
          end
        end
      end
    end

    def permissions_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :lock, "Permissions", "Request each protected capability"
          [%w[Camera camera camera_permission_rev], %w[Microphone microphone microphone_permission_rev],
           %w[Location location location_permission_rev], %w[Bluetooth bluetooth bluetooth_permission_rev],
           %w[Contacts contacts contacts_permission_rev], %w[Calendar calendar calendar_permission_rev]].each_slice(2) do |pair|
            row spacing: 8 do
              pair.each do |label, key, revision|
                button label, id: "permission.#{key}", width: 152, height: 48,
                       bordered: true, foreground: WHITE, background: PANEL_ALT, accent: CYAN do
                  state.public_send("#{revision}=", state.public_send(revision) + 1)
                  log("Requested #{label.downcase} permission")
                end
              end
            end
          end

          camera_permission_node = camera_permission id: :camera_permission, auto_request: false
          microphone_permission_node = microphone_permission id: :microphone_permission, auto_request: false
          location_permission_node = location_permission id: :location_permission, availability: :when_in_use, auto_request: false
          bluetooth_permission_node = bluetooth_permission id: :bluetooth_permission, communication_modes: [:access], auto_request: false
          contacts_permission_node = contacts_permission id: :contacts_permission, access_mode: :read_write, auto_request: false
          calendar_permission_node = calendar_permission id: :calendar_permission, access_mode: :full, auto_request: false
          [[camera_permission_node, :camera_permission_rev, "Camera"],
           [microphone_permission_node, :microphone_permission_rev, "Microphone"],
           [location_permission_node, :location_permission_rev, "Location"],
           [bluetooth_permission_node, :bluetooth_permission_rev, "Bluetooth"],
           [contacts_permission_node, :contacts_permission_rev, "Contacts"],
           [calendar_permission_node, :calendar_permission_rev, "Calendar"]].each do |node, revision, label|
            bind(node, :request_revision) { state.public_send(revision) }
            on(node, :change) { |event| log("#{label} permission: #{event.fetch("status", event.fetch("value", "changed"))}") }
            on(node, :error) { |event| log("#{label} permission error: #{event.fetch("message", "unknown")}") }
          end
        end
      end
    end

    def camera_audio_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :camera, "Camera + audio", "Preview, photo, record, and replay"
          session = capture_session id: :studio_session, width: 312, height: 210,
                                    camera_active: state.camera_active,
                                    camera_enabled: !state.audio_input_enabled,
                                    audio_input_enabled: state.audio_input_enabled,
                                    video_output_enabled: true
          bind(session, :camera_active) { state.camera_active }
          bind(session, :camera_enabled) { !state.audio_input_enabled }
          bind(session, :audio_input_enabled) { state.audio_input_enabled }
          on(session, :error) { |event| log("Capture session: #{event.fetch("message", "failed")}") }

          photo = image_capture session, id: :photo_capture, quality: :high,
                                command: state.photo_command,
                                command_revision: state.photo_revision
          bind_command(photo, :photo_command, :photo_revision)
          on(photo, :captured) { log("Photo captured in memory") }
          on(photo, :saved) { |event| log("Photo saved: #{event.fetch("path", "")}") }
          on(photo, :error) { |event| log("Photo error: #{event.fetch("message", "unknown")}") }

          recorder = media_recorder session, id: :audio_recorder, quality: :high,
                                    media_format: :m4a, audio_codec: :aac,
                                    command: state.record_command,
                                    command_revision: state.record_revision
          bind_command(recorder, :record_command, :record_revision)
          on(recorder, :record) { state.recording = true; log("Audio recording started") }
          on(recorder, :pause) { log("Audio recording paused") }
          on(recorder, :stop) do
            state.recording = false
            state.audio_input_enabled = false
            log("Audio recording stopped")
          end
          on(recorder, :duration) { |event| state.record_duration = event.fetch("value", 0).to_i }
          on(recorder, :location) { |event| state.recording_url = event.fetch("value", "").to_s }
          on(recorder, :error) { |event| log("Recorder error: #{event.fetch("message", "unknown")}") }

          player = media_player state.recording_url, id: :recording_player,
                                command: state.play_command, command_revision: state.play_revision,
                                volume: 1.0
          bind(player, :source) { state.recording_url }
          bind_command(player, :play_command, :play_revision)
          on(player, :play) { log("Playing latest recording") }
          on(player, :error) { |event| log("Playback error: #{event.fetch("message", "unknown")}") }

          row spacing: 7 do
            camera_button = button "Camera", id: :camera_toggle, width: 98, height: 50,
                                   icon: :camera, background: state.camera_active ? "#174b3a" : PANEL_ALT,
                                   foreground: state.camera_active ? MINT : WHITE do
              state.camera_active = !state.camera_active
              log(state.camera_active ? "Camera preview enabled" : "Camera preview disabled")
            end
            bind(camera_button, :background) { state.camera_active ? "#174b3a" : PANEL_ALT }
            button "Photo", id: :take_photo, width: 98, height: 50, icon: :image,
                   background: PANEL_ALT, foreground: WHITE do
              issue(:photo_command, :photo_revision, "capture")
            end
            record_button = button "Record", id: :record_audio, width: 98, height: 50,
                                   icon: state.recording ? :stop : :music,
                                   background: state.recording ? "#572334" : PANEL_ALT,
                                   foreground: state.recording ? RED : WHITE do
              unless state.recording
                state.camera_active = false
                state.audio_input_enabled = true
              end
              issue(:record_command, :record_revision, state.recording ? "stop" : "record")
            end
            bind(record_button, :text) { state.recording ? "Stop" : "Record" }
            bind(record_button, :icon) { state.recording ? "stop" : "music" }
            bind(record_button, :background) { state.recording ? "#572334" : PANEL_ALT }
          end
          row spacing: 8 do
            button "Play", id: :play_recording, width: 152, height: 48, icon: :play,
                   bordered: true, background: "#153455", foreground: CYAN do
              issue(:play_command, :play_revision, "play")
            end
            button "Stop", id: :stop_recording_playback, width: 152, height: 48, icon: :stop,
                   bordered: true, background: PANEL_ALT, foreground: WHITE do
              issue(:play_command, :play_revision, "stop")
            end
          end
          duration = text "Recorded 0.0 s", id: :record_duration, size: 11, color: MUTED, wrap: false
          bind(duration, :text) { "Recorded #{(state.record_duration.to_f / 1000.0).round(1)} s" }
        end
      end
    end

    def motion_touch_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :phone, "Motion + touch", "Shake detection and native handlers"
          sensor = accelerometer id: :motion_sensor, active: state.motion_active,
                                 data_rate: 20, skip_duplicates: true do |event|
            x = event.fetch("x", 0).to_f
            y = event.fetch("y", 0).to_f
            z = event.fetch("z", 0).to_f
            magnitude = Math.sqrt((x * x) + (y * y) + (z * z)).round(1)
            values = state.motion_values.dup
            values.shift while values.length >= 18
            values << magnitude
            transaction do
              state.motion_values = values
              state.motion_magnitude = magnitude
              state.shake_count = state.shake_count + 1 if magnitude > 20
            end
          end
          bind(sensor, :active) { state.motion_active }
          on(sensor, :error) { |event| log("Accelerometer: #{event.fetch("message", "unavailable")}") }
          row spacing: 10, alignment: :center do
            motion_toggle = toggle_switch id: :motion_toggle, checked: state.motion_active,
                                          accent: MINT do |event|
              state.motion_active = event.fetch("value", false) == true
              log(state.motion_active ? "Motion sampling enabled" : "Motion sampling disabled")
            end
            bind(motion_toggle, :checked) { state.motion_active }
            magnitude = text "0.0 g", id: :motion_magnitude, size: 22, bold: true,
                             width: 118, color: MINT, wrap: false
            bind(magnitude, :text) { "#{state.motion_magnitude} m/s²" }
            shakes = badge "0 SHAKES", id: :shake_count, background: "#3e2f17", foreground: GOLD
            bind(shakes, :value) { "#{state.shake_count} SHAKES" }
          end
          chart = line_chart state.motion_values, id: :motion_chart, width: 312, height: 132,
                             color: CYAN, fill_color: "#2255ddff", grid_color: "#22486c",
                             minimum: 0, maximum: 28, show_grid: true, show_points: false
          bind(chart, :values) { state.motion_values }

          touch = tap_area id: :tap_test, width: 312, height: 82, long_press_threshold: 0.6 do
            rectangle width: 312, height: 82, radius: 15, color: "#153455",
                      border_color: CYAN, border_width: 1 do
              center width: 312, height: 82 do
                text "TAP · DOUBLE TAP · HOLD", size: 13, bold: true, color: CYAN, wrap: false
              end
            end
          end
          on(touch, :tap) { |event| state.touch_status = "Tap @ #{event.fetch("x", 0).round},#{event.fetch("y", 0).round}" }
          on(touch, :double_tap) { state.touch_status = "Double tap" }
          on(touch, :long_press) { state.touch_status = "Long press" }

          drag = drag_area id: :drag_test, width: 312, height: 82,
                           minimum_x: -80, maximum_x: 80, minimum_y: -18, maximum_y: 18 do
            rectangle width: 92, height: 62, radius: 16, color: "#214a3b",
                      border_color: MINT, border_width: 1 do
              center width: 92, height: 62 do
                text "DRAG", bold: true, color: MINT, wrap: false
              end
            end
          end
          on(drag, :drag) { |event| state.touch_status = "Drag #{event.fetch("x", 0).round}, #{event.fetch("y", 0).round}" }
          on(drag, :drag_end) { log("Drag gesture completed") }
          touch_status = text "Waiting for touch", id: :touch_status, size: 12, color: MUTED, wrap: false
          bind(touch_status, :text) { state.touch_status }
        end
      end
    end

    def location_charts_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :location, "Location + charts", "GPS feeds a native map and gauges"
          position = position_source id: :gps_source, active: state.location_active,
                                     update_interval: 1000 do |event|
            transaction do
              state.latitude = event.fetch("latitude", state.latitude).to_f
              state.longitude = event.fetch("longitude", state.longitude).to_f
              state.location_accuracy = event.fetch("horizontal_accuracy", 0).to_f.round(1)
            end
          end
          bind(position, :active) { state.location_active }
          on(position, :error) { |event| log("Location: #{event.fetch("message", "unavailable")}") }
          row spacing: 10, alignment: :center do
            location_toggle = toggle_switch id: :location_toggle, checked: state.location_active,
                                            accent: CYAN do |event|
              state.location_active = event.fetch("value", false) == true
            end
            bind(location_toggle, :checked) { state.location_active }
            coordinates = text "37.3349, -122.0090", id: :coordinates, size: 12,
                               width: 226, color: WHITE, wrap: false
            bind(coordinates, :text) { "#{state.latitude.round(4)}, #{state.longitude.round(4)} · ±#{state.location_accuracy}m" }
          end
          map_view = map id: :kitchen_map, plugin: :osm, latitude: state.latitude,
                         longitude: state.longitude, zoom: 13, width: 312, height: 220 do
            marker = map_marker id: :current_position, latitude: state.latitude,
                                longitude: state.longitude, width: 42, height: 42 do
              badge "YOU", background: CYAN, foreground: BG
            end
            bind(marker, :latitude) { state.latitude }
            bind(marker, :longitude) { state.longitude }
          end
          bind(map_view, :latitude) { state.latitude }
          bind(map_view, :longitude) { state.longitude }
          on(map_view, :error) { |event| log("Map: #{event.fetch("message", "failed")}") }
          row spacing: 8 do
            radial_gauge [], id: :trust_gauge, value: 92, minimum: 0, maximum: 100,
                         width: 98, height: 112, color: MINT, track_color: "#18352e",
                         thickness: 9, label: "Runtime", label_format: "%{value}%", font_size: 10
            bar_chart [72, 88, 64, 96, 91], id: :service_chart,
                      labels: %w[UI Media Touch GPS Web], width: 206, height: 112,
                      colors: [CYAN, MINT, GOLD, "#8b9dff", RED], grid_color: "#24486c",
                      minimum: 0, maximum: 100, show_grid: true
          end
        end
      end
    end

    def services_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :globe, "Speech + web + system", "Native services and persistence"
          speech = text_to_speech "Zui mobile services are running natively.", id: :speech_service,
                                  auto_speak: false,
                                  command: state.speech_command,
                                  command_revision: state.speech_revision
          bind_command(speech, :speech_command, :speech_revision)
          on(speech, :state) { |event| log("Speech: #{event.fetch("value", "changed")}") }
          on(speech, :error) { |event| log("Speech error: #{event.fetch("message", "unknown")}") }
          row spacing: 8 do
            button "Speak", id: :speak_button, width: 152, height: 48, icon: :volume_high,
                   background: "#153455", foreground: CYAN do
              issue(:speech_command, :speech_revision, "say")
            end
            button "Stop", id: :stop_speech, width: 152, height: 48, icon: :stop,
                   background: PANEL_ALT, foreground: WHITE do
              issue(:speech_command, :speech_revision, "stop")
            end
          end

          keyboard_settings id: :keyboard_preferences, locale: "en_US", close_on_return: true
          keyboard_context id: :keyboard_context_probe, watch: true
          keyboard_text_field "", id: :native_keyboard_field,
                              placeholder: "Open Qt keyboard and type…", enter_key: :done,
                              width: 312, height: 54 do |event|
            state.typed_text = event.fetch("value", "").to_s
          end
          web = web_view id: :welcome_web, html: "<html><body style='background:#0d1b2d;color:#55ddff;font-family:sans-serif;padding:18px'><h2>Native WebView</h2><p>Zui loaded this local HTML without a server.</p></body></html>",
                         width: 312, height: 170, local_storage: true, javascript: true
          on(web, :error) { |event| log("WebView: #{event.fetch("message", "failed")}") }

          network = network_status id: :network_probe, watch: true do |event|
            state.network_label = "#{event.fetch("reachability", "unknown")} · #{event.fetch("transport", "unknown")}"
          end
          on(network, :information) do |event|
            state.network_label = "#{event.fetch("reachability", "unknown")} · #{event.fetch("transport", "unknown")}"
          end
          system_info id: :system_probe do |event|
            state.system_label = "#{event.fetch("pretty_product_name", "Device")} · #{event.fetch("current_cpu_architecture", "CPU")}"
          end
          paths = standard_paths :app_data, id: :paths_probe
          on(paths, :resolved) { |event| state.storage_label = event.fetch("location", "unknown").to_s }
          settings({ "launches" => 1, "trusted" => true }, id: :settings_probe)

          network_text = text "Network: checking", id: :network_label, size: 11, color: MUTED, width: 312, wrap: true
          bind(network_text, :text) { "Network: #{state.network_label}" }
          system_text = text "System: checking", id: :system_label, size: 11, color: MUTED, width: 312, wrap: true
          bind(system_text, :text) { "System: #{state.system_label}" }
          storage_text = text "Storage: resolving", id: :storage_label, size: 10, color: MUTED, width: 312, wrap: true
          bind(storage_text, :text) { "Storage: #{state.storage_label}" }
        end
      end
    end

    def modern_navigation_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :menu, "Modern navigation", "Tabs, swipe pages, and bottom destinations"

          tabs_node = tabs %w[Overview Activity Profile], id: :modern_tabs,
                           current_index: state.tab_index, width: 312, height: 178,
                           tab_height: 46, background: PANEL_ALT,
                           content_background: "#0a1727", foreground: WHITE,
                           muted: MUTED, accent: CYAN, border_color: BORDER, radius: 14 do
            rectangle width: 312, height: 132, color: "#0a1727" do
              center width: 312, height: 132 do
                text "OVERVIEW · Native tab content", size: 12, bold: true,
                     color: CYAN, wrap: false
              end
            end
            rectangle width: 312, height: 132, color: "#0a1727" do
              center width: 312, height: 132 do
                text "ACTIVITY · Reactive Ruby state", size: 12, bold: true,
                     color: MINT, wrap: false
              end
            end
            rectangle width: 312, height: 132, color: "#0a1727" do
              center width: 312, height: 132 do
                text "PROFILE · Touch-ready controls", size: 12, bold: true,
                     color: GOLD, wrap: false
              end
            end
          end
          bind(tabs_node, :current_index) { state.tab_index }
          on(tabs_node, :change) do |event|
            state.tab_index = event.fetch("value", 0).to_i
            log("Tab changed to #{state.tab_index + 1}")
          end

          swipe = swipe_view id: :modern_swipe_pages, current_index: state.swipe_index,
                             width: 312, height: 108, interactive: true,
                             background: "#0a1727", border_color: BORDER, radius: 14 do
            [
              ["SWIPE LEFT", CYAN],
              ["NATIVE PAGE", MINT],
              ["SWIPE RIGHT", GOLD]
            ].each do |label, color|
              rectangle width: 312, height: 108, radius: 14, color: "#0a1727" do
                center width: 312, height: 108 do
                  text label, size: 13, bold: true, color: color, wrap: false
                end
              end
            end
          end
          bind(swipe, :current_index) { state.swipe_index }
          on(swipe, :change) { |event| state.swipe_index = event.fetch("value", 0).to_i }
          indicator = page_indicator 3, id: :modern_page_indicator,
                                     current_index: state.swipe_index, interactive: true,
                                     width: 92, height: 30, accent: CYAN, foreground: MUTED
          bind(indicator, :current_index) { state.swipe_index }
          on(indicator, :change) { |event| state.swipe_index = event.fetch("value", 0).to_i }

          text "BOTTOM NAVIGATION", size: 10, bold: true, color: MUTED, wrap: false
          bottom_nav = tab_bar [
            { label: "Home", icon: :house },
            { label: "Activity", icon: :terminal },
            { label: "Settings", icon: :gear }
          ], id: :bottom_navigation, current_index: state.bottom_nav_index,
             position: :bottom, width: 312, height: 58, background: PANEL_ALT,
             foreground: WHITE, muted: MUTED, accent: MINT,
             border_color: BORDER, radius: 14
          bind(bottom_nav, :current_index) { state.bottom_nav_index }
          on(bottom_nav, :change) do |event|
            state.bottom_nav_index = event.fetch("value", 0).to_i
            log("Bottom destination changed to #{state.bottom_nav_index + 1}")
          end
        end
      end
    end

    def picker_calendar_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :calendar, "Pickers + calendar", "Dates, time, color, ranges, and numeric input"

          date = date_picker state.selected_date, id: :modern_date_picker,
                             label: "Date", format: "MMM d, yyyy",
                             minimum: "2025-01-01", maximum: "2030-12-31",
                             width: 312, height: 50, popup_width: 312,
                             foreground: WHITE, muted: MUTED,
                             background: PANEL_ALT, popup_background: PANEL,
                             border_color: BORDER, accent: CYAN, radius: 13 do |event|
            state.selected_date = event.fetch("value", state.selected_date).to_s
            log("Date selected: #{state.selected_date}")
          end
          bind(date, :date) { state.selected_date }

          time = time_picker state.selected_time, id: :modern_time_picker,
                             label: "Time", use_24_hour: false, minute_step: 5,
                             width: 312, height: 50, popup_width: 312,
                             foreground: WHITE, muted: MUTED,
                             background: PANEL_ALT, popup_background: PANEL,
                             border_color: BORDER, accent: MINT, radius: 13 do |event|
            state.selected_time = event.fetch("value", state.selected_time).to_s
            log("Time selected: #{state.selected_time}")
          end
          bind(time, :time) { state.selected_time }

          color = color_picker state.selected_color, id: :modern_color_picker,
                               label: "Accent color", title: "Choose an accent",
                               show_alpha: true, width: 312, height: 50,
                               foreground: WHITE, background: PANEL_ALT,
                               border_color: BORDER, radius: 13 do |event|
            state.selected_color = event.fetch("value", state.selected_color).to_s
            log("Accent changed: #{state.selected_color}")
          end
          bind(color, :color) { state.selected_color }

          range_label = text "Comfort range 18–24 °C", id: :modern_range_label,
                             size: 11, color: MUTED, wrap: false
          bind(range_label, :text) { "Comfort range #{state.range_lower.round}–#{state.range_upper.round} °C" }
          range = range_slider state.range_lower, state.range_upper,
                               id: :modern_range_picker, minimum: 10, maximum: 35,
                               step: 1, snap: :release, width: 312, height: 48,
                               foreground: WHITE, background: PANEL_ALT, accent: GOLD do |event|
            transaction do
              state.range_lower = event.fetch("lower", state.range_lower).to_f
              state.range_upper = event.fetch("upper", state.range_upper).to_f
            end
          end
          bind(range, :lower) { state.range_lower }
          bind(range, :upper) { state.range_upper }

          row spacing: 18, alignment: :center do
            dial_node = dial state.dial_value, id: :modern_dial, minimum: 0,
                             maximum: 100, step: 5, snap: :release, size: 112,
                             foreground: WHITE, background: PANEL_ALT, accent: CYAN do |event|
              state.dial_value = event.fetch("value", state.dial_value).to_f
            end
            bind(dial_node, :value) { state.dial_value }
            spin = spin_box state.guest_count, id: :modern_spin_box,
                            minimum: 1, maximum: 12, step: 1,
                            prefix: "Guests ", width: 180,
                            foreground: WHITE, background: PANEL_ALT, accent: MINT do |event|
              state.guest_count = event.fetch("value", state.guest_count).to_i
            end
            bind(spin, :value) { state.guest_count }
          end

          calendar_node = calendar state.selected_date, id: :modern_calendar,
                                   width: 312, height: 330, show_week_numbers: true,
                                   background: "#0a1727", header_background: PANEL_ALT,
                                   selected_background: CYAN, today_background: "#17344f",
                                   foreground: WHITE, muted: MUTED, accent: CYAN,
                                   border_color: BORDER, radius: 14
          bind(calendar_node, :date) { state.selected_date }
          on(calendar_node, :change) do |event|
            state.selected_date = event.fetch("value", state.selected_date).to_s
            log("Calendar selected #{state.selected_date}")
          end
        end
      end
    end

    def overlay_card
      card width: 348, padding: 18, color: PANEL, border_color: BORDER do
        column spacing: 12 do
          section_title :menu, "Overlays + surfaces", "Drawer, dialogs, and a draggable bottom sheet"
          [["Drawer", :open_navigation_drawer, :drawer_open],
           ["Dialog", :open_standard_dialog, :dialog_open],
           ["Alert", :open_alert_dialog, :alert_open],
           ["Bottom sheet", :open_bottom_sheet, :sheet_open]].each_slice(2) do |pair|
            row spacing: 8 do
              pair.each do |label, id, state_name|
                button label, id: id, width: 152, height: 50,
                       background: PANEL_ALT, foreground: WHITE, bordered: true do
                  state.public_send("#{state_name}=", true)
                  log("Opened #{label.downcase}")
                end
              end
            end
          end

          drawer_node = drawer id: :modern_navigation_drawer,
                               opened: state.drawer_open, edge: :left,
                               modal: true, dim: true, interactive: true,
                               close_policy: %i[escape outside], layout: :column,
                               spacing: 14, padding: 22, width: 306, height: 760,
                               background: PANEL, foreground: WHITE,
                               border_color: BORDER, radius: 18 do
            text "ZUI NAVIGATION", size: 20, bold: true, color: CYAN, wrap: false
            text "A real edge-swipe Qt drawer", size: 11, color: MUTED, wrap: false
            divider color: BORDER, width: 262
            %w[Dashboard Devices Automations Settings].each_with_index do |label, index|
              button label, id: "drawer.destination.#{index}", width: 262, height: 52,
                     icon: %i[house phone refresh gear][index],
                     background: index.zero? ? "#153455" : PANEL_ALT,
                     foreground: index.zero? ? CYAN : WHITE do
                state.drawer_open = false
                log("Drawer selected #{label}")
              end
            end
            button "Close drawer", id: :close_navigation_drawer,
                   width: 262, height: 52, background: "#572334", foreground: RED do
              state.drawer_open = false
            end
          end
          bind(drawer_node, :opened) { state.drawer_open }
          on(drawer_node, :close) { state.drawer_open = false }

          standard_dialog = dialog "Modern dialog", id: :modern_standard_dialog,
                                   opened: state.dialog_open, centered: true,
                                   standard_buttons: %i[ok cancel], width: 336, height: 248,
                                   modal: true, dim: true, layout: :column,
                                   spacing: 12, padding: 20,
                                   background: PANEL, foreground: WHITE,
                                   border_color: BORDER, radius: 18 do
            text "A touch-friendly Qt dialog rendered from Ruby.", size: 13,
                 color: WHITE, width: 288, wrap: true
            text "Accept or dismiss it to verify the complete event path.", size: 11,
                 color: MUTED, width: 288, wrap: true
          end
          bind(standard_dialog, :opened) { state.dialog_open }
          on(standard_dialog, :accept) { state.dialog_open = false; log("Dialog accepted") }
          on(standard_dialog, :reject) { state.dialog_open = false; log("Dialog dismissed") }
          on(standard_dialog, :close) { state.dialog_open = false }

          alert = alert_dialog "Service verified", "Zui overlays are running through native Qt Quick Controls.",
                               id: :modern_alert_dialog, severity: :success,
                               opened: state.alert_open, centered: true,
                               informative_text: "This is the production alert adapter.",
                               standard_buttons: [:ok], width: 336, height: 300,
                               background: PANEL, header_background: PANEL_ALT,
                               footer_background: PANEL_ALT, foreground: WHITE,
                               muted: MUTED, accent: MINT, border_color: BORDER, radius: 18
          bind(alert, :opened) { state.alert_open }
          on(alert, :accept) { state.alert_open = false; log("Alert accepted") }
          on(alert, :reject) { state.alert_open = false }
          on(alert, :close) { state.alert_open = false }

          sheet = bottom_sheet id: :modern_bottom_sheet, opened: state.sheet_open,
                               modal: true, dim: true, dismissible: true, draggable: true,
                               height: 272, max_width: 366, margin: 12,
                               dismiss_threshold: 0.3, padding: 20,
                               background: PANEL, foreground: WHITE,
                               muted: MUTED, accent: CYAN, border_color: BORDER, radius: 20 do
            text "QUICK ACTIONS", size: 18, bold: true, color: WHITE, wrap: false
            text "Drag down to dismiss this native bottom sheet.", size: 11,
                 color: MUTED, width: 310, wrap: true
            row spacing: 8 do
              button "Apply", id: :sheet_apply, width: 151, height: 52,
                     background: "#174b3a", foreground: MINT do
                state.sheet_open = false
                log("Bottom sheet applied")
              end
              button "Cancel", id: :sheet_cancel, width: 151, height: 52,
                     background: PANEL_ALT, foreground: WHITE do
                state.sheet_open = false
              end
            end
          end
          bind(sheet, :opened) { state.sheet_open }
          on(sheet, :close) { state.sheet_open = false }
          on(sheet, :dismiss) { state.sheet_open = false; log("Bottom sheet dismissed") }
        end
      end
    end

    def diagnostics_card
      card width: 348, padding: 18, color: "#0a1727", border_color: BORDER do
        column spacing: 10 do
          section_title :terminal, "Diagnostics", "The latest real event or failure"
          log_text = text "Runtime initialized", id: :diagnostic_log, size: 12, color: MINT,
                          width: 312, wrap: true
          bind(log_text, :text) { state.log_line }
          row spacing: 8 do
            button "Copy report", id: :copy_report, width: 152, height: 46, icon: :copy,
                   background: PANEL_ALT, foreground: WHITE do
              transaction do
                state.clipboard_text = "Zui Kitchen Sink: #{state.log_line}"
                state.clipboard_revision += 1
                state.log_line = "Diagnostics copied"
              end
            end
            button "Reset", id: :reset_diagnostics, width: 152, height: 46, icon: :reset,
                   background: PANEL_ALT, foreground: WHITE do
              transaction do
                state.shake_count = 0
                state.motion_values = [0, 0, 0, 0, 0, 0]
                state.log_line = "Diagnostics reset"
              end
            end
          end
          copy = clipboard id: :report_clipboard, watch: false, revision: state.clipboard_revision
          bind(copy, :text) { state.clipboard_text }
          bind(copy, :revision) { state.clipboard_revision }
          on(copy, :copied) { log("Diagnostics copied to clipboard") }
        end
      end
    end

    def kitchen_sink
      safe_area id: :device_safe_area, edges: [:top, :bottom, :left, :right], background: BG do
        responsive_view id: :kitchen_feed, card_width: 348, spacing: 12, padding: 12,
                        max_columns: 4, background: BG do
          hero_card
          permissions_card
          camera_audio_card
          motion_touch_card
          location_charts_card
          services_card
          modern_navigation_card
          picker_calendar_card
          overlay_card
          diagnostics_card
        end
      end
      keyboard = virtual_keyboard id: :qt_keyboard, z: 2000
      on(keyboard, :error) { |event| log("Keyboard: #{event.fetch("message", "failed")}") }
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      state :runtime_ready, true
      state :log_line, "Runtime initialized"
      state :camera_permission_rev, 0
      state :microphone_permission_rev, 0
      state :location_permission_rev, 0
      state :bluetooth_permission_rev, 0
      state :contacts_permission_rev, 0
      state :calendar_permission_rev, 0
      state :camera_active, false
      state :audio_input_enabled, false
      state :photo_command, ""
      state :photo_revision, 0
      state :record_command, ""
      state :record_revision, 0
      state :recording, false
      state :record_duration, 0
      state :recording_url, ""
      state :play_command, ""
      state :play_revision, 0
      state :motion_active, false
      state :motion_values, [0, 0, 0, 0, 0, 0]
      state :motion_magnitude, 0.0
      state :shake_count, 0
      state :touch_status, "Waiting for touch"
      state :location_active, false
      state :latitude, 37.3349
      state :longitude, -122.0090
      state :location_accuracy, 0.0
      state :speech_command, ""
      state :speech_revision, 0
      state :typed_text, ""
      state :network_label, "checking"
      state :system_label, "checking"
      state :storage_label, "resolving"
      state :tab_index, 0
      state :swipe_index, 0
      state :bottom_nav_index, 0
      state :selected_date, "2026-08-27"
      state :selected_time, "09:30"
      state :selected_color, CYAN
      state :range_lower, 18.0
      state :range_upper, 24.0
      state :dial_value, 65.0
      state :guest_count, 4
      state :drawer_open, false
      state :dialog_open, false
      state :alert_open, false
      state :sheet_open, false
      state :clipboard_revision, 0
      state :clipboard_text, nil

      app :main, title: "Zui Mobile Kitchen Sink", width: 390, height: 844,
                 min_width: 320, min_height: 568, color: BG, fullscreen: true do
        kitchen_sink
      end
    end
  end

  def self.run = build.run
end
