# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require "timeout"
require_relative "../lib/zui"

class ZuiTest < Minitest::Test
  def test_application_ui_modules_are_scoped_to_one_builder
    ui = Module.new do
      def status_panel
        card(id: :status_panel) { text "Online" }
      end
    end
    application = Zui::Application.new(ui:) do
      app { status_panel }
    end

    assert_equal "card", application.tree.fetch("main").fetch("children").first.fetch("type")
    refute Zui::Builder.instance_methods.include?(:status_panel)
  end

  def test_application_rejects_non_module_ui_extensions
    error = assert_raises(ArgumentError) do
      Zui::Application.new(ui: Object.new) { app { text "Invalid" } }
    end

    assert_includes error.message, "ui extensions must be modules"
  end

  def test_responsive_layouts_and_icon_catalog_are_built_in
    application = Zui::Application.new do
      app do
        card padding: 20 do
          column_layout spacing: 12 do
            row_layout fill_width: true do
              icon :phone, color: "#7aa2f7"
              text "Devices", fill_width: true
            end
            flow width: 480 do
              button "Android", icon: :android
              button "iPhone", icon: :apple
            end
          end
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    render = messages(output).find { |message| message["type"] == "render" }
    card_node = render.dig("surfaces", "main", "children", 0)
    column = card_node.dig("children", 0)
    row = column.dig("children", 0)

    assert_equal "card", card_node.fetch("type")
    assert_equal "column_layout", column.fetch("type")
    assert_equal true, row.dig("props", "fill_width")
    assert_equal "phone", row.dig("children", 0, "props", "name")
    assert_includes Zui::ICON_NAMES, :android
    assert_includes Zui::ICON_NAMES, :apple
  ensure
    application&.stop
  end

  def test_aspect_ratio_is_a_typed_container
    application = Zui::Application.new do
      app do
        aspect_ratio ratio: 16.0 / 9, width: 320 do
          image "preview.png"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "aspect_ratio", node.fetch("type")
    assert_in_delta 16.0 / 9, node.dig("props", "ratio")
    assert_equal 320, node.dig("props", "width")
    assert_equal "image", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_constrained_box_is_a_typed_container
    application = Zui::Application.new do
      app do
        constrained_box min_width: 200, max_width: 600, min_height: 100 do
          text "Bounded content"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "constrained_box", node.fetch("type")
    assert_equal 200, node.dig("props", "min_width")
    assert_equal 600, node.dig("props", "max_width")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_fitted_box_is_a_typed_container
    application = Zui::Application.new do
      app do
        fitted_box width: 300, height: 180, fit: :cover, alignment: :top_left do
          image "hero.png", width: 640, height: 480
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "fitted_box", node.fetch("type")
    assert_equal "cover", node.dig("props", "fit")
    assert_equal "top_left", node.dig("props", "alignment")
    assert_equal "image", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_wrap_is_a_typed_responsive_container
    application = Zui::Application.new do
      app do
        wrap width: 360, spacing: 12, layout_direction: :right_to_left do
          button "One"
          button "Two"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "wrap", node.fetch("type")
    assert_equal 360, node.dig("props", "width")
    assert_equal "right_to_left", node.dig("props", "layout_direction")
    assert_equal %w[button button], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_split_view_is_a_typed_resizable_container
    application = Zui::Application.new do
      app do
        split_view width: 640, height: 360, orientation: :horizontal do
          rectangle preferred_width: 220
          rectangle fill_width: true
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "split_view", node.fetch("type")
    assert_equal "horizontal", node.dig("props", "orientation")
    assert_equal 220, node.dig("children", 0, "props", "preferred_width")
    assert_equal true, node.dig("children", 1, "props", "fill_width")
  ensure
    application&.stop
  end

  def test_stack_layout_is_a_typed_indexed_container
    application = Zui::Application.new do
      app do
        stack_layout current_index: 1, width: 480 do
          text "First"
          text "Second"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "stack_layout", node.fetch("type")
    assert_equal 1, node.dig("props", "current_index")
    assert_equal %w[First Second], node.fetch("children").map { |child| child.dig("props", "text") }
  ensure
    application&.stop
  end

  def test_layout_item_proxy_accepts_a_node_as_its_typed_target
    application = Zui::Application.new do
      app do
        target = card(id: :shared_card) { text "Shared" }
        row_layout do
          layout_item_proxy target, preferred_width: 240, fill_height: true, margins: 8
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    children = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children")
    proxy = children.fetch(1).fetch("children").fetch(0)

    assert_equal "layout_item_proxy", proxy.fetch("type")
    assert_equal "shared_card", proxy.dig("props", "target")
    assert_equal 240, proxy.dig("props", "preferred_width")
    assert_equal true, proxy.dig("props", "fill_height")
    assert_equal 8, proxy.dig("props", "margins")
  ensure
    application&.stop
  end

  def test_layout_item_proxy_rejects_an_empty_target
    error = assert_raises(ArgumentError) do
      Zui::Application.new { app { layout_item_proxy "" } }
    end
    assert_equal "layout_item_proxy target cannot be empty", error.message
  end

  def test_window_is_a_typed_native_secondary_surface_container
    application = Zui::Application.new do
      app do
        window "Inspector", id: :inspector, width: 520, height: 360,
               visible: true, modality: :window_modal, flags: %i[dialog stay_on_top] do
          text "Independent content"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "window", node.fetch("type")
    assert_equal "Inspector", node.dig("props", "title")
    assert_equal 520, node.dig("props", "width")
    assert_equal "window_modal", node.dig("props", "modality")
    assert_equal %w[dialog stay_on_top], node.dig("props", "flags")
    assert_equal "Independent content", node.dig("children", 0, "props", "text")
  ensure
    application&.stop
  end

  def test_application_window_is_a_typed_controls_window_container
    application = Zui::Application.new do
      app do
        application_window "Settings", id: :settings_window, width: 720, height: 540,
                           visible: false, background: "#101820", layout_direction: :right_to_left do
          text "Settings content"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "application_window", node.fetch("type")
    assert_equal "Settings", node.dig("props", "title")
    assert_equal 720, node.dig("props", "width")
    assert_equal "#101820", node.dig("props", "background")
    assert_equal "right_to_left", node.dig("props", "layout_direction")
    assert_equal "Settings content", node.dig("children", 0, "props", "text")
  ensure
    application&.stop
  end

  def test_loader_is_a_typed_lazy_container
    application = Zui::Application.new do
      app do
        loader active: true, asynchronous: true do
          card { text "Loaded later" }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "loader", node.fetch("type")
    assert_equal true, node.dig("props", "active")
    assert_equal true, node.dig("props", "asynchronous")
    assert_equal "card", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_flickable_is_a_typed_kinetic_scroll_container
    application = Zui::Application.new do
      app do
        flickable width: 400, height: 260, direction: :both, bounds_behavior: :overshoot do
          column { text "Scrollable" }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "flickable", node.fetch("type")
    assert_equal "both", node.dig("props", "direction")
    assert_equal "overshoot", node.dig("props", "bounds_behavior")
    assert_equal "column", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_focus_scope_is_a_typed_focus_container
    application = Zui::Application.new do
      app do
        focus_scope active_focus: true do
          text_field "ready"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "focus_scope", node.fetch("type")
    assert_equal true, node.dig("props", "active_focus")
    assert_equal "text_field", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_flipable_is_a_typed_two_face_container
    application = Zui::Application.new do
      app do
        flipable flipped: true, axis: :horizontal, duration: 450 do
          card { text "Front" }
          card { text "Back" }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "flipable", node.fetch("type")
    assert_equal true, node.dig("props", "flipped")
    assert_equal "horizontal", node.dig("props", "axis")
    assert_equal %w[card card], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_border_image_is_a_typed_nine_slice_container
    application = Zui::Application.new do
      app do
        border_image "frame.png", border_left: 12, border_top: 10, horizontal_tile: :repeat do
          text "Framed"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "border_image", node.fetch("type")
    assert_equal "frame.png", node.dig("props", "source")
    assert_equal 12, node.dig("props", "border_left")
    assert_equal "repeat", node.dig("props", "horizontal_tile")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_tooltip_is_a_typed_builtin_component
    application = Zui::Application.new do
      app do
        tooltip "Refresh devices", visible: true, delay: 250
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "tooltip", node.fetch("type")
    assert_equal "Refresh devices", node.dig("props", "text")
    assert_equal 250, node.dig("props", "delay")
  ensure
    application&.stop
  end

  def test_label_is_a_typed_styled_text_control
    application = Zui::Application.new do
      app { label "Documentation", bold: true, elide: :right, maximum_lines: 2 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "label", node.fetch("type")
    assert_equal "Documentation", node.dig("props", "text")
    assert_equal "right", node.dig("props", "elide")
    assert_equal 2, node.dig("props", "maximum_lines")
  ensure
    application&.stop
  end

  def test_rich_text_is_an_explicit_typed_markup_component
    application = Zui::Application.new do
      app { rich_text '<b>Omarchy</b> <a href="docs">docs</a>', link_color: "#7aa2f7" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "rich_text", node.fetch("type")
    assert_includes node.dig("props", "text"), "<b>Omarchy</b>"
    assert_equal "#7aa2f7", node.dig("props", "link_color")
  ensure
    application&.stop
  end

  def test_markdown_is_a_dedicated_typed_document_component
    application = Zui::Application.new do
      app { markdown "# Zui\n\n[Guide](guide.md)", base_url: "file:///docs/" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "markdown", node.fetch("type")
    assert_includes node.dig("props", "text"), "# Zui"
    assert_equal "file:///docs/", node.dig("props", "base_url")
  ensure
    application&.stop
  end

  def test_selectable_text_is_a_typed_read_only_selection_component
    application = Zui::Application.new do
      app { selectable_text "Copy this value", selection_color: "#7aa2f7", wrap: false }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "selectable_text", node.fetch("type")
    assert_equal "Copy this value", node.dig("props", "text")
    assert_equal "#7aa2f7", node.dig("props", "selection_color")
    assert_equal false, node.dig("props", "wrap")
  ensure
    application&.stop
  end

  def test_animated_image_is_a_typed_native_playback_component
    application = Zui::Application.new do
      app { animated_image "spinner.gif", playing: true, speed: 1.5, fill_mode: :cover }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "animated_image", node.fetch("type")
    assert_equal "spinner.gif", node.dig("props", "source")
    assert_equal 1.5, node.dig("props", "speed")
    assert_equal "cover", node.dig("props", "fill_mode")
  ensure
    application&.stop
  end

  def test_vector_image_is_a_typed_native_svg_component
    application = Zui::Application.new do
      app { vector_image "logo.svg", renderer: :curve, fill_mode: :contain, animation_loops: 3 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "vector_image", node.fetch("type")
    assert_equal "logo.svg", node.dig("props", "source")
    assert_equal "curve", node.dig("props", "renderer")
    assert_equal 3, node.dig("props", "animation_loops")
  ensure
    application&.stop
  end

  def test_model_view_3d_is_a_typed_interactive_glb_component
    application = Zui::Application.new do
      app do
        model_view_3d "scene.glb", rotation_x: -90, rotation_y: 12,
                                   zoom: 1.4,
                                   interactive: true, reset_revision: 3
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "model_view_3d", node.fetch("type")
    assert_equal "scene.glb", node.dig("props", "source")
    assert_equal(-90, node.dig("props", "rotation_x"))
    assert_equal 1.4, node.dig("props", "zoom")
    assert_equal 3, node.dig("props", "reset_revision")
  ensure
    application&.stop
  end

  def test_font_loader_is_a_typed_native_font_resource
    application = Zui::Application.new do
      app { font_loader "fonts/Inter.woff2" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "font_loader", node.fetch("type")
    assert_equal "fonts/Inter.woff2", node.dig("props", "source")
  ensure
    application&.stop
  end

  def test_text_metrics_is_a_typed_native_measurement_component
    application = Zui::Application.new do
      app { text_metrics "Measure me", font_size: 18, bold: true, elide: :right, elide_width: 100 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "text_metrics", node.fetch("type")
    assert_equal "Measure me", node.dig("props", "text")
    assert_equal 18, node.dig("props", "font_size")
    assert_equal "right", node.dig("props", "elide")
  ensure
    application&.stop
  end

  def test_video_is_a_typed_native_multimedia_component
    application = Zui::Application.new do
      app { video "intro.mp4", auto_play: true, volume: 0.7, fill_mode: :cover }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "video", node.fetch("type")
    assert_equal "intro.mp4", node.dig("props", "source")
    assert_equal true, node.dig("props", "auto_play")
    assert_equal 0.7, node.dig("props", "volume")
  ensure
    application&.stop
  end

  def test_audio_is_a_typed_native_media_player_component
    application = Zui::Application.new do
      app { audio "alert.ogg", playback: :play, loops: 2, volume: 0.5 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "audio", node.fetch("type")
    assert_equal "alert.ogg", node.dig("props", "source")
    assert_equal "play", node.dig("props", "playback")
    assert_equal 0.5, node.dig("props", "volume")
  ensure
    application&.stop
  end

  def test_avatar_is_a_typed_image_with_explicit_empty_source_initials
    application = Zui::Application.new do
      app { avatar "profile.png", name: "Ada Lovelace", size: 64 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "avatar", node.fetch("type")
    assert_equal "profile.png", node.dig("props", "source")
    assert_equal "Ada Lovelace", node.dig("props", "name")
    assert_equal 64, node.dig("props", "size")
  ensure
    application&.stop
  end

  def test_badge_is_a_typed_value_or_dot_component
    application = Zui::Application.new do
      app { badge 120, maximum: 99, background: "#f7768e" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "badge", node.fetch("type")
    assert_equal 120, node.dig("props", "value")
    assert_equal 99, node.dig("props", "maximum")
    assert_equal "#f7768e", node.dig("props", "background")
  ensure
    application&.stop
  end

  def test_chip_is_a_typed_selectable_and_deletable_component
    application = Zui::Application.new do
      app { chip "Ruby", icon: :ruby, selected: true, deletable: true }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "chip", node.fetch("type")
    assert_equal "Ruby", node.dig("props", "text")
    assert_equal "ruby", node.dig("props", "icon")
    assert_equal true, node.dig("props", "deletable")
  ensure
    application&.stop
  end

  def test_divider_is_a_typed_oriented_line_component
    application = Zui::Application.new do
      app { divider orientation: :vertical, length: 120, thickness: 2, indent: 8 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "divider", node.fetch("type")
    assert_equal "vertical", node.dig("props", "orientation")
    assert_equal 120, node.dig("props", "length")
    assert_equal 2, node.dig("props", "thickness")
  ensure
    application&.stop
  end

  def test_bar_icon_button_registers_click_handler_and_optical_properties
    application = Zui::Application.new do
      bar_widget do
        bar_icon_button :wifi, slot_size: 30, optical_size: 20 do
          state.clicked = true
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    render = messages(output).find { |message| message["type"] == "render" }
    node = render.dig("surfaces", "bar", "children", 0)

    assert_equal "bar_icon_button", node.fetch("type")
    assert_equal "wifi", node.dig("props", "icon")
    assert_equal 30, node.dig("props", "slot_size")
    assert_includes node.fetch("events"), "click"
  ensure
    application&.stop
  end

  def test_round_button_is_a_typed_native_checkable_control
    application = Zui::Application.new do
      app { round_button "", icon: :plus, diameter: 48, checkable: true, checked: true }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "round_button", node.fetch("type")
    assert_equal "plus", node.dig("props", "icon")
    assert_equal 48, node.dig("props", "diameter")
    assert_equal true, node.dig("props", "checked")
  ensure
    application&.stop
  end

  def test_tool_button_is_a_typed_native_toolbar_control
    application = Zui::Application.new do
      app { tool_button "", icon: :edit, width: 42, checkable: true }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "tool_button", node.fetch("type")
    assert_equal "edit", node.dig("props", "icon")
    assert_equal 42, node.dig("props", "width")
    assert_equal true, node.dig("props", "checkable")
  ensure
    application&.stop
  end

  def test_delay_button_is_a_typed_hold_to_activate_control
    application = Zui::Application.new do
      app { delay_button "Delete", delay: 1500, width: 160 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "delay_button", node.fetch("type")
    assert_equal "Delete", node.dig("props", "text")
    assert_equal 1500, node.dig("props", "delay")
    assert_equal 160, node.dig("props", "width")
  ensure
    application&.stop
  end

  def test_bar_indicator_serializes_active_and_inactive_states
    application = Zui::Application.new do
      bar_widget do
        bar_indicator :wifi, active: true, inactive_icon: :xmark,
                             active_tooltip: "Online", inactive_tooltip: "Offline"
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "bar", "children", 0)

    assert_equal "bar_indicator", node.fetch("type")
    assert_equal true, node.dig("props", "active")
    assert_equal "wifi", node.dig("props", "active_icon")
    assert_equal "xmark", node.dig("props", "inactive_icon")
  ensure
    application&.stop
  end

  def test_border_overlay_accepts_gradient_border_data
    application = Zui::Application.new do
      app do
        border_overlay width: 240, height: 120, width_spec: 2,
                       gradient_colors: ["#7aa2f7", "#bb9af7"], gradient_angle: 45
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "border_overlay", node.fetch("type")
    assert_equal ["#7aa2f7", "#bb9af7"], node.dig("props", "gradient_colors")
    assert_equal 45, node.dig("props", "gradient_angle")
  ensure
    application&.stop
  end

  def test_key_catcher_is_a_container_with_semantic_keyboard_events
    application = Zui::Application.new do
      app do
        key_catcher blocked: false do
          text "Keyboard content"
          on(:move) { |_event| }
          on(:text) { |_event| }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "key_catcher", node.fetch("type")
    assert_equal "text", node.dig("children", 0, "type")
    assert_includes node.fetch("events"), "move"
    assert_includes node.fetch("events"), "text"
  ensure
    application&.stop
  end

  def test_checkbox_is_a_value_input_with_change_handler
    application = Zui::Application.new do
      state :enabled, false
      app do
        checkbox "Enable Wi-Fi", checked: state.enabled do |event|
          state.enabled = event.fetch("value")
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "checkbox", node.fetch("type")
    assert_equal "Enable Wi-Fi", node.dig("props", "label")
    assert_equal false, node.dig("props", "checked")
    assert_includes node.fetch("events"), "change"
  ensure
    application&.stop
  end

  def test_radio_button_is_a_typed_native_selection_control
    application = Zui::Application.new do
      app { radio_button "Ruby", value: :ruby, checked: true, indicator_size: 22 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "radio_button", node.fetch("type")
    assert_equal "Ruby", node.dig("props", "label")
    assert_equal "ruby", node.dig("props", "value")
    assert_equal true, node.dig("props", "checked")
  ensure
    application&.stop
  end

  def test_radio_group_is_a_typed_mutually_exclusive_options_control
    application = Zui::Application.new do
      app { radio_group :ruby, options: [{ label: "Ruby", value: :ruby }, { label: "QML", value: :qml }], orientation: :horizontal }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "radio_group", node.fetch("type")
    assert_equal "ruby", node.dig("props", "value")
    assert_equal "Ruby", node.dig("props", "options", 0, "label")
    assert_equal "horizontal", node.dig("props", "orientation")
  ensure
    application&.stop
  end

  def test_line_chart_is_a_specific_reactive_data_component
    application = Zui::Application.new do
      state :samples, [12, 18, 15, 27]
      app do
        chart = line_chart state.samples, labels: %w[Mon Tue Wed Thu], fill_color: "#337aa2f7"
        bind(chart, :values) { state.samples }
        on(chart, :select) { |_event| }
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "line_chart", node.fetch("type")
    assert_equal [12, 18, 15, 27], node.dig("props", "values")
    assert_equal %w[Mon Tue Wed Thu], node.dig("props", "labels")
    assert_includes node.fetch("events"), "select"
  ensure
    application&.stop
  end

  def test_bar_chart_is_a_specific_data_component
    application = Zui::Application.new do
      app { bar_chart [4, 8, 6], labels: %w[A B C], colors: ["#7aa2f7", "#bb9af7"] }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "bar_chart", node.fetch("type")
    assert_equal [4, 8, 6], node.dig("props", "values")
    assert_equal %w[A B C], node.dig("props", "labels")
  ensure
    application&.stop
  end

  def test_area_chart_is_a_specific_data_component
    application = Zui::Application.new do
      app { area_chart [3, 7, 5], labels: %w[Jan Feb Mar], fill_color: "#447aa2f7" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "area_chart", node.fetch("type")
    assert_equal [3, 7, 5], node.dig("props", "values")
    assert_equal "#447aa2f7", node.dig("props", "fill_color")
  ensure
    application&.stop
  end

  def test_gauges_accept_the_generic_series_argument
    application = Zui::Application.new do
      app do
        gauge [45], value: 45, minimum: 0, maximum: 100
        radial_gauge [72], value: 72, minimum: 0, maximum: 100
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    nodes = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children")

    assert_equal "gauge", nodes.fetch(0).fetch("type")
    assert_equal [45], nodes.fetch(0).dig("props", "values")
    assert_equal "radial_gauge", nodes.fetch(1).fetch("type")
    assert_equal [72], nodes.fetch(1).dig("props", "values")
  ensure
    application&.stop
  end

  def build_counter
    Zui::Application.new do
      state :count, 0

      bar_widget do
        text "Ruby UI"
        on_click { open_panel :counter }
      end

      panel :counter do
        column do
          text(id: :count) { "Count: #{state.count}" }
          button "Increment", id: :increment do
            state.count += 1
          end
          button "Reset", id: :reset do
            state.count = 0
          end
        end
      end
    end
  end

  def messages(output)
    output.string.lines.map { |line| JSON.parse(line) }
  end

  def event(id, seq: 1, surface: "counter", name: "click", payload: {})
    JSON.generate(
      "v" => 1,
      "type" => "event",
      "surface" => surface,
      "id" => id,
      "event" => name,
      "seq" => seq,
      "payload" => payload
    )
  end

  def test_initial_render_contains_named_surfaces_and_controls
    app = build_counter
    output = StringIO.new
    app.start(output: output, error: StringIO.new)

    ready, render = messages(output)
    assert_equal "ready", ready.fetch("type")
    assert_equal %w[bar counter], ready.fetch("surfaces")
    assert_equal "render", render.fetch("type")
    assert_equal "Count: 0", render.dig("surfaces", "counter", "children", 0, "children", 0, "props", "text")
  end

  def test_app_surface_serializes_window_options_separately_from_controls
    application = Zui::Application.new do
      app :main, title: "Dashboard", width: 900, height: 600, min_width: 480 do
        text "Ready"
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    render = output.string.lines.map { |line| JSON.parse(line) }.find { |message| message["type"] == "render" }

    assert_equal({ "title" => "Dashboard", "width" => 900, "height" => 600, "min_width" => 480 },
                 render.dig("surface_options", "main"))
    refute_includes(render.dig("surfaces", "main").fetch("props", {}), "title")
  ensure
    application&.stop
  end

  def test_app_surface_rejects_unknown_window_options
    error = assert_raises(ArgumentError) do
      Zui::Application.new { app(:main, decorations: false) { text "No" } }
    end
    assert_includes error.message, "unsupported app options"
  end

  def test_click_executes_ruby_handler_and_emits_only_set_patch_plus_ack
    app = build_counter
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("increment", seq: 7))

    patch, ack = messages(output)
    assert_equal({
      "v" => 1,
      "type" => "patch",
      "op" => "set",
      "id" => "count",
      "property" => "text",
      "value" => "Count: 1"
    }, patch)
    assert_equal "ack", ack.fetch("type")
    assert_equal 7, ack.fetch("seq")
  end

  def test_reset_does_not_emit_a_patch_when_value_is_already_zero
    app = build_counter
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("reset"))

    assert_equal ["ack"], messages(output).map { |message| message.fetch("type") }
  end

  def test_bar_click_emits_only_the_whitelisted_open_panel_effect
    app = build_counter
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("bar", surface: "bar"))

    effect, ack = messages(output)
    assert_equal "effect", effect.fetch("type")
    assert_equal "open_panel", effect.fetch("name")
    assert_equal({ "surface" => "counter" }, effect.fetch("payload"))
    assert_equal "ack", ack.fetch("type")
  end

  def test_unknown_events_and_invalid_json_are_rejected
    app = build_counter
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("missing"))
    app.receive("{not json}\n")

    types = messages(output).map { |message| message.fetch("type") }
    assert_equal ["protocol_error", "protocol_error"], types
  end

  def test_control_must_belong_to_the_claimed_surface
    app = build_counter
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("increment", surface: "bar"))

    message = messages(output).fetch(0)
    assert_equal "protocol_error", message.fetch("type")
    assert_match(/does not belong/, message.fetch("message"))
  end

  def test_duplicate_ids_are_rejected
    error = assert_raises(ArgumentError) do
      Zui::Application.new do
        panel :main do
          text "one", id: :same
          text "two", id: :same
        end
      end
    end

    assert_match(/duplicate control id/, error.message)
  end


  def test_form_widgets_keep_typed_properties_and_deliver_change_payloads
    selected = nil
    typed = nil
    application = Zui::Application.new do
      panel :settings do
        dropdown "dark", id: :theme, options: [
          { value: :dark, label: "Dark" },
          { value: :light, label: "Light" }
        ] do |event|
          selected = event.fetch("value")
        end
        multi_select %w[wifi bluetooth], options: %w[wifi bluetooth audio]
        slider 0.5, minimum: 0, maximum: 1
        toggle "Notifications", checked: true
        text_field "hello", id: :name, placeholder: "Name" do |event|
          typed = event.fetch("value")
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)

    props = application.tree.dig("settings", "children")
    assert_equal [{ "value" => "dark", "label" => "Dark" }, { "value" => "light", "label" => "Light" }], props[0].dig("props", "options")
    assert_equal %w[wifi bluetooth], props[1].dig("props", "values")

    application.receive(event("theme", surface: "settings", name: "change", payload: { "value" => "light" }))
    assert_equal "light", selected
    application.receive(event("name", surface: "settings", name: "input", payload: { "value" => "Ada" }))
    assert_equal "Ada", typed
  end

  def test_arbitrary_properties_can_be_reactively_bound
    application = Zui::Application.new do
      state :enabled, false
      panel :settings do
        control = toggle "Feature", id: :feature
        bind(control, :checked) { state.enabled }
        button("Enable", id: :enable) { state.enabled = true }
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    application.receive(event("enable", surface: "settings"))
    patch = messages(output).first
    assert_equal "checked", patch.fetch("property")
    assert_equal true, patch.fetch("value")
  end

  def test_qml_components_are_registered_with_a_validated_schema
    app = Zui::Application.new do
      register_component :custom_sparkline, qml: "Sparkline.qml", properties: %i[values color], events: %i[click]
      app do
        component :custom_sparkline, id: :history, values: [1, 3, 2], color: "#ff0000"
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    render = messages(output).last

    assert_equal "Sparkline.qml", render.dig("components", "custom_sparkline", "qml")
    assert_equal false, render.dig("components", "custom_sparkline", "built_in")
    assert_equal true, render.dig("components", "text", "built_in")
    assert_equal [1, 3, 2], render.dig("surfaces", "main", "children", 0, "props", "values")
  end

  def test_component_schema_rejects_unknown_properties_and_unsafe_paths
    assert_raises(ArgumentError) do
      Zui::Application.new do
        register_component :unsafe, qml: "../Unsafe.qml", properties: [:value]
        app { component :unsafe, value: 1 }
      end
    end

    assert_raises(ArgumentError) do
      Zui::Application.new do
        app { component :text, executable: "oops" }
      end
    end
  end

  def test_native_component_protocol_includes_property_and_event_maps
    application = Zui::Application.new do
      register_component :native_dial, qml: "Dial.qml", properties: %i[current_value],
                         property_map: { current_value: :value }, events: %i[change],
                         event_map: { change: :moved }
      app { component :native_dial, current_value: 42 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    render = messages(output).find { |message| message["type"] == "render" }
    schema = render.dig("components", "native_dial")
    assert_equal "value", schema.dig("property_map", "current_value")
    assert_equal "moved", schema.dig("event_map", "change")
    assert schema.fetch("auto_bind")
  ensure
    application&.stop
  end

  def test_reactive_binding_emits_a_validated_animation_descriptor
    app = Zui::Application.new do
      state :level, 0.0
      panel :meter do
        meter = progress 0.0, id: :meter
        bind(meter, :value, animation: animation(duration: 320, easing: :out_cubic, delay: 10)) { state.level }
        button("Fill", id: :fill) { state.level = 1.0 }
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("fill", surface: "meter"))
    patch = messages(output).first
    assert_equal({ "duration" => 320, "easing" => "out_cubic", "delay" => 10 }, patch.fetch("animation"))
    assert_equal 1.0, patch.fetch("value")
  end

  def test_animation_rejects_unbounded_values_and_unknown_easing
    assert_raises(ArgumentError) { Zui::Animation.new(duration: 60_001) }
    assert_raises(ArgumentError) { Zui::Animation.new(easing: :javascript) }
  end

  def test_events_are_explicitly_subscribed_per_node
    received = nil
    app = Zui::Application.new do
      panel :actions do
        control = button "Menu", id: :menu
        on(control, :right_click) { |payload| received = payload.fetch("button") }
        on(control, :mount) {}
      end
    end
    node = app.tree.dig("actions", "children", 0)
    assert_equal %w[right_click mount], node.fetch("events")

    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    app.receive(event("menu", surface: "actions", name: "right_click", payload: { "button" => 2 }))
    assert_equal 2, received
  end

  def test_undeclared_component_event_is_rejected_at_build_time
    assert_raises(ArgumentError) do
      Zui::Application.new do
        panel :main do
          label = text "No clicks", id: :label
          on(label, :clicked_twice) {}
        end
      end
    end
  end

  def test_reactive_list_models_preserve_typed_rows_and_activation_payloads
    activated = nil
    app = Zui::Application.new do
      state :rows, [{ id: 1, label: "One" }]
      panel :items do
        list = component :list_view, id: :items, items: state.rows, selected: 1
        bind(list, :items) { state.rows }
        on(list, :activate) { |payload| activated = payload.fetch("item") }
        button("Add", id: :add) { state.rows = state.rows + [{ id: 2, label: "Two" }] }
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("add", surface: "items"))
    patch = messages(output).first
    assert_equal [{ "id" => 1, "label" => "One" }, { "id" => 2, "label" => "Two" }], patch.fetch("value")

    app.receive(event("items", surface: "items", name: "activate", payload: {
      "value" => 2, "index" => 1, "item" => { "id" => 2, "label" => "Two" }
    }))
    assert_equal({ "id" => 2, "label" => "Two" }, activated)
  end

  def test_transactions_emit_only_final_reactive_values
    app = Zui::Application.new do
      state :first, 0
      state :second, 0
      panel :main do
        label = text "", id: :total
        bind(label, :text) { "Total: #{state.first + state.second}" }
        button("Batch", id: :batch) do
          transaction do
            state.first = 2
            state.second = 3
          end
        end
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind
    app.receive(event("batch", surface: "main"))

    patches = messages(output).select { |message| message["type"] == "patch" }
    assert_equal 1, patches.length
    assert_equal "Total: 5", patches.first.fetch("value")
  end

  def test_transactions_emit_multiple_reactive_values_as_one_atomic_patch_batch
    app = Zui::Application.new do
      state :first, 0
      state :second, 0
      panel :main do
        first = text "", id: :first_value
        second = text "", id: :second_value
        bind(first, :text) { "First: #{state.first}" }
        bind(second, :text) { "Second: #{state.second}" }
        button("Batch", id: :batch) do
          transaction do
            state.first = 2
            state.second = 3
          end
        end
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("batch", surface: "main"))

    patches = messages(output).select { |message| message["type"] == "patch" }
    assert_equal 1, patches.length
    assert_equal "batch", patches.first.fetch("op")
    assert_equal %w[first_value second_value], patches.first.fetch("patches").map { _1.fetch("id") }
    assert_equal ["First: 2", "Second: 3"], patches.first.fetch("patches").map { _1.fetch("value") }
  end

  def test_values_reject_cycles_nonfinite_numbers_and_excessive_depth
    cyclic = []
    cyclic << cyclic
    assert_raises(ArgumentError) { Zui::Value.normalize(cyclic, property: :items) }
    assert_raises(ArgumentError) { Zui::Value.normalize(Float::INFINITY, property: :value) }
    deep = 34.times.reduce("end") { |value| [value] }
    assert_raises(ArgumentError) { Zui::Value.normalize(deep, property: :items) }
  end

  def test_state_update_is_atomic_across_threads
    store = Zui::StateStore.new(->(*) {})
    store.define(:count, 0)
    threads = 8.times.map { Thread.new { 250.times { store.update(:count) { |value| value + 1 } } } }
    threads.each(&:join)
    assert_equal 2_000, store.count
  end

  def test_managed_tasks_update_state_and_stop_with_the_application
    app = Zui::Application.new do
      state :status, "waiting"
      panel :main do
        label = text "", id: :status
        bind(label, :text) { state.status }
      end
      after(0.01) { state.status = "ready" }
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    Timeout.timeout(1) do
      sleep(0.005) until messages(output).any? { |message| message["type"] == "patch" }
    end
    assert_equal "ready", messages(output).find { |message| message["type"] == "patch" }.fetch("value")
    app.stop
  end

  def test_periodic_tasks_are_cooperatively_cancelled
    ticks = Queue.new
    app = Zui::Application.new do
      panel(:main) { text "timer" }
      every(0.005, immediate: true) { ticks << true }
    end
    app.start(output: StringIO.new, error: StringIO.new)
    Timeout.timeout(1) { sleep(0.002) while ticks.empty? }
    app.stop
    count = ticks.size
    sleep(0.02)
    assert_equal count, ticks.size
  end

  def test_dynamic_containers_reconcile_conditionals_and_event_handlers
    clicked = []
    app = Zui::Application.new do
      state :items, [{ id: "one", label: "One" }]
      panel :main do
        dynamic id: :content do
          state.items.each do |item|
            button item.fetch(:label), id: "item.#{item.fetch(:id)}" do
              clicked << item.fetch(:id)
            end
          end
          text "Empty", id: :empty if state.items.empty?
        end
        button("Replace", id: :replace) do
          state.items = [{ id: "two", label: "Two" }]
        end
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("replace", surface: "main"))
    patch = messages(output).find { |message| message["op"] == "replace_children" }
    assert_equal "content", patch.fetch("id")
    assert_equal ["item.two"], patch.fetch("children").map { |node| node.fetch("id") }

    app.receive(event("item.two", surface: "main"))
    assert_equal ["two"], clicked
    app.receive(event("item.one", surface: "main"))
    assert_equal "protocol_error", messages(output).last.fetch("type")
  end

  def test_dynamic_container_does_not_patch_an_unchanged_subtree
    app = Zui::Application.new do
      state :unrelated, 0
      panel :main do
        dynamic(id: :stable) { text "Same", id: :same }
        button("Change", id: :change) { state.unrelated += 1 }
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind
    app.receive(event("change", surface: "main"))
    refute messages(output).any? { |message| message["op"] == "replace_children" }
  end

  def test_dynamic_container_preserves_input_when_only_its_value_changes
    app = Zui::Application.new do
      state :name, ""
      panel :main do
        dynamic id: :form do
          column do
            field = text_field "", id: :name do |payload|
              state.name = payload.fetch("value")
            end
            bind(field, :text) { state.name }
          end
        end
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind

    app.receive(event("name", surface: "main", name: "input", payload: { "value" => "A" }))
    refute messages(output).any? { |message| message["type"] == "patch" }
    assert_equal "A", app.state.name
  end

  def test_dynamic_regions_use_independent_generated_id_scopes_when_they_grow
    app = Zui::Application.new do
      state :items, ["one"]
      panel :main do
        dynamic(id: :first) { state.items.each { |item| text item } }
        dynamic(id: :second) { text "Stable" }
        button("Grow", id: :grow) { state.items = %w[one two three four] }
      end
    end
    output = StringIO.new
    error = StringIO.new
    app.start(output:, error:)
    output.truncate(0)
    output.rewind

    app.receive(event("grow", surface: "main"))
    assert_empty error.string
    assert_equal 4, app.tree.dig("main", "children", 0, "children").length
    assert_equal "second.text.1", app.tree.dig("main", "children", 1, "children", 0, "id")
  end

  def test_imperative_animation_emits_parallel_tracks
    app = Zui::Application.new do
      panel :main do
        label = text "Animate", id: :label
        button("Go", id: :go) do
          animate label, { opacity: 0.25, scale: 1.2 }, duration: 280, easing: :out_cubic
        end
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind
    app.receive(event("go", surface: "main"))

    patch = messages(output).first
    assert_equal "animate", patch.fetch("op")
    assert_equal %w[opacity scale], patch.fetch("tracks").map { |track| track.fetch("property") }
    assert_equal [1.0, 1.0], patch.fetch("tracks").map { |track| track.fetch("from") }
    assert_equal [0.25, 1.2], patch.fetch("tracks").map { |track| track.fetch("to") }
  end

  def test_text_area_is_a_typed_multiline_value_input
    application = Zui::Application.new do
      app { text_area "First line\nSecond line", width: 360, height: 160, wrap: :word }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "text_area", node.fetch("type")
    assert_includes node.dig("props", "text"), "Second line"
    assert_equal 360, node.dig("props", "width")
    assert_equal "word", node.dig("props", "wrap")
  ensure
    application&.stop
  end

  def test_search_field_is_a_typed_native_suggestion_input
    application = Zui::Application.new do
      app { search_field "oma", suggestions: %w[omarchy zui], live: true, current_index: 0 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "search_field", node.fetch("type")
    assert_equal "oma", node.dig("props", "text")
    assert_equal %w[omarchy zui], node.dig("props", "suggestions")
    assert_equal true, node.dig("props", "live")
  ensure
    application&.stop
  end

  def test_password_field_is_a_typed_masked_revealable_input
    application = Zui::Application.new do
      app { password_field "secret", placeholder: "Password", revealable: true, revealed: false }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "password_field", node.fetch("type")
    assert_equal "secret", node.dig("props", "text")
    assert_equal true, node.dig("props", "revealable")
    assert_equal false, node.dig("props", "revealed")
  ensure
    application&.stop
  end

  def test_range_slider_is_a_typed_native_two_handle_input
    application = Zui::Application.new do
      app { range_slider 20, 80, minimum: 0, maximum: 100, step: 5, snap: :release }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "range_slider", node.fetch("type")
    assert_equal 20, node.dig("props", "lower")
    assert_equal 80, node.dig("props", "upper")
    assert_equal "release", node.dig("props", "snap")
  ensure
    application&.stop
  end

  def test_dial_is_a_typed_native_angular_input
    application = Zui::Application.new do
      app { dial 25, minimum: 0, maximum: 100, step: 5, input_mode: :circular, size: 120 }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "dial", node.fetch("type")
    assert_equal 25, node.dig("props", "value")
    assert_equal 100, node.dig("props", "maximum")
    assert_equal "circular", node.dig("props", "input_mode")
  ensure
    application&.stop
  end

  def test_spin_box_is_a_typed_native_integer_input
    application = Zui::Application.new do
      app { spin_box 12, minimum: 0, maximum: 24, step: 2, prefix: "#", suffix: " px" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "spin_box", node.fetch("type")
    assert_equal 12, node.dig("props", "value")
    assert_equal 2, node.dig("props", "step")
    assert_equal " px", node.dig("props", "suffix")
  ensure
    application&.stop
  end

  def test_double_spin_box_is_a_typed_native_floating_input
    application = Zui::Application.new do
      app { double_spin_box 1.25, minimum: 0.0, maximum: 10.0, step: 0.25, decimals: 2, suffix: "x" }
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }.dig("surfaces", "main", "children", 0)

    assert_equal "double_spin_box", node.fetch("type")
    assert_equal 1.25, node.dig("props", "value")
    assert_equal 0.25, node.dig("props", "step")
    assert_equal 2, node.dig("props", "decimals")
  ensure
    application&.stop
  end

  def test_color_picker_is_a_typed_native_color_input
    application = Zui::Application.new do
      app do
        color_picker "#336699", label: "Accent", title: "Choose accent",
                     show_alpha: true, opened: false
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "color_picker", node.fetch("type")
    assert_equal "#336699", node.dig("props", "color")
    assert_equal "Accent", node.dig("props", "label")
    assert_equal "Choose accent", node.dig("props", "title")
    assert_equal true, node.dig("props", "show_alpha")
    assert_equal false, node.dig("props", "opened")
  ensure
    application&.stop
  end

  def test_date_picker_is_a_typed_native_calendar_input
    application = Zui::Application.new do
      app do
        date_picker "2026-08-22", label: "Due date", format: "MMM d, yyyy",
                    minimum: "2026-01-01", maximum: "2026-12-31", close_on_select: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "date_picker", node.fetch("type")
    assert_equal "2026-08-22", node.dig("props", "date")
    assert_equal "Due date", node.dig("props", "label")
    assert_equal "MMM d, yyyy", node.dig("props", "format")
    assert_equal "2026-01-01", node.dig("props", "minimum")
    assert_equal "2026-12-31", node.dig("props", "maximum")
    assert_equal true, node.dig("props", "close_on_select")
  ensure
    application&.stop
  end

  def test_time_picker_is_a_typed_native_time_input
    application = Zui::Application.new do
      app do
        time_picker "14:35:20", label: "Reminder", use_24_hour: false,
                    show_seconds: true, minute_step: 5, second_step: 10
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "time_picker", node.fetch("type")
    assert_equal "14:35:20", node.dig("props", "time")
    assert_equal "Reminder", node.dig("props", "label")
    assert_equal false, node.dig("props", "use_24_hour")
    assert_equal true, node.dig("props", "show_seconds")
    assert_equal 5, node.dig("props", "minute_step")
    assert_equal 10, node.dig("props", "second_step")
  ensure
    application&.stop
  end

  def test_file_picker_is_a_typed_native_filesystem_input
    application = Zui::Application.new do
      app do
        file_picker "/tmp/report.md", label: "Report", mode: :save,
                    filters: ["Markdown (*.md)", "All files (*)"],
                    current_folder: "/tmp", default_suffix: "md"
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "file_picker", node.fetch("type")
    assert_equal "/tmp/report.md", node.dig("props", "path")
    assert_equal "Report", node.dig("props", "label")
    assert_equal "save", node.dig("props", "mode")
    assert_equal ["Markdown (*.md)", "All files (*)"], node.dig("props", "filters")
    assert_equal "/tmp", node.dig("props", "current_folder")
    assert_equal "md", node.dig("props", "default_suffix")
  ensure
    application&.stop
  end

  def test_folder_picker_is_a_typed_native_directory_input
    application = Zui::Application.new do
      app do
        folder_picker "/tmp/output", label: "Output", title: "Choose output folder",
                      current_folder: "/tmp", native_dialog: false
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "folder_picker", node.fetch("type")
    assert_equal "/tmp/output", node.dig("props", "path")
    assert_equal "Output", node.dig("props", "label")
    assert_equal "Choose output folder", node.dig("props", "title")
    assert_equal "/tmp", node.dig("props", "current_folder")
    assert_equal false, node.dig("props", "native_dialog")
  ensure
    application&.stop
  end

  def test_font_picker_is_a_typed_native_font_input
    application = Zui::Application.new do
      app do
        font_picker "JetBrains Mono", label: "Editor font", point_size: 12,
                    weight: 600, italic: true, underline: false
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "font_picker", node.fetch("type")
    assert_equal "JetBrains Mono", node.dig("props", "family")
    assert_equal "Editor font", node.dig("props", "label")
    assert_equal 12, node.dig("props", "point_size")
    assert_equal 600, node.dig("props", "weight")
    assert_equal true, node.dig("props", "italic")
    assert_equal false, node.dig("props", "underline")
  ensure
    application&.stop
  end

  def test_dialog_button_box_is_a_typed_native_action_row
    application = Zui::Application.new do
      app do
        dialog_button_box %i[save cancel], orientation: :horizontal, position: :footer,
                          custom_buttons: [{ text: "Preview", role: :action }]
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "dialog_button_box", node.fetch("type")
    assert_equal %w[save cancel], node.dig("props", "buttons")
    assert_equal "horizontal", node.dig("props", "orientation")
    assert_equal "footer", node.dig("props", "position")
    assert_equal [{ "text" => "Preview", "role" => "action" }], node.dig("props", "custom_buttons")
  ensure
    application&.stop
  end

  def test_action_is_a_typed_native_command
    application = Zui::Application.new do
      app do
        action "Save", id: :save_action, icon: :save, shortcut: "Ctrl+S",
               checkable: true, checked: false
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "action", node.fetch("type")
    assert_equal "save_action", node.fetch("id")
    assert_equal "Save", node.dig("props", "text")
    assert_equal "save", node.dig("props", "icon")
    assert_equal "Ctrl+S", node.dig("props", "shortcut")
    assert_equal true, node.dig("props", "checkable")
    assert_equal false, node.dig("props", "checked")
  ensure
    application&.stop
  end

  def test_action_group_serializes_action_node_references
    application = Zui::Application.new do
      app do
        first = action "First", id: :first_action, checkable: true
        second = action "Second", id: :second_action, checkable: true
        action_group [first, second], id: :choices, checked: second, exclusive: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    children = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children")
    node = children.find { |child| child["type"] == "action_group" }

    assert_equal "choices", node.fetch("id")
    assert_equal %w[first_action second_action], node.dig("props", "action_ids")
    assert_equal "second_action", node.dig("props", "checked_action")
    assert_equal true, node.dig("props", "exclusive")
  ensure
    application&.stop
  end

  def test_page_is_a_typed_native_navigation_container
    application = Zui::Application.new do
      app do
        page "Settings", id: :settings, header_text: "Account", footer_text: "Saved",
             layout: :column, spacing: 12, padding: 20 do
          text "Profile"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "page", node.fetch("type")
    assert_equal "settings", node.fetch("id")
    assert_equal "Settings", node.dig("props", "title")
    assert_equal "Account", node.dig("props", "header_text")
    assert_equal "Saved", node.dig("props", "footer_text")
    assert_equal "column", node.dig("props", "layout")
    assert_equal 12, node.dig("props", "spacing")
    assert_equal 20, node.dig("props", "padding")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_pane_is_a_typed_native_content_surface
    application = Zui::Application.new do
      app do
        pane id: :account_pane, layout: :row, spacing: 10, padding: 16,
             left_padding: 24, background: "#112233", radius: 8 do
          text "Account"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "pane", node.fetch("type")
    assert_equal "account_pane", node.fetch("id")
    assert_equal "row", node.dig("props", "layout")
    assert_equal 10, node.dig("props", "spacing")
    assert_equal 16, node.dig("props", "padding")
    assert_equal 24, node.dig("props", "left_padding")
    assert_equal "#112233", node.dig("props", "background")
    assert_equal 8, node.dig("props", "radius")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_frame_is_a_typed_native_bordered_container
    application = Zui::Application.new do
      app do
        frame id: :details_frame, layout: :column, spacing: 8, padding: 14,
              border_color: "#89b482", border_width: 2, radius: 6 do
          text "Details"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "frame", node.fetch("type")
    assert_equal "details_frame", node.fetch("id")
    assert_equal "column", node.dig("props", "layout")
    assert_equal 8, node.dig("props", "spacing")
    assert_equal 14, node.dig("props", "padding")
    assert_equal "#89b482", node.dig("props", "border_color")
    assert_equal 2, node.dig("props", "border_width")
    assert_equal 6, node.dig("props", "radius")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_group_box_is_a_typed_native_titled_container
    application = Zui::Application.new do
      app do
        group_box "Network", id: :network_group, layout: :row, spacing: 9,
                  padding: 12, title_alignment: :center, border_color: "#89b482" do
          text "Connected"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "group_box", node.fetch("type")
    assert_equal "network_group", node.fetch("id")
    assert_equal "Network", node.dig("props", "title")
    assert_equal "row", node.dig("props", "layout")
    assert_equal 9, node.dig("props", "spacing")
    assert_equal 12, node.dig("props", "padding")
    assert_equal "center", node.dig("props", "title_alignment")
    assert_equal "#89b482", node.dig("props", "border_color")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_tabs_is_a_typed_native_navigation_container
    application = Zui::Application.new do
      app do
        tabs %w[General Advanced], id: :settings_tabs, current_index: 1,
             position: :bottom, tab_height: 48 do
          pane { text "General page" }
          page "Advanced" do
            text "Advanced page"
          end
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "tabs", node.fetch("type")
    assert_equal "settings_tabs", node.fetch("id")
    assert_equal %w[General Advanced], node.dig("props", "labels")
    assert_equal 1, node.dig("props", "current_index")
    assert_equal "bottom", node.dig("props", "position")
    assert_equal 48, node.dig("props", "tab_height")
    assert_equal %w[pane page], node.fetch("children").map { |child| child.fetch("type") }
    assert_equal "Advanced", node.dig("children", 1, "props", "title")
  ensure
    application&.stop
  end

  def test_tab_bar_is_a_typed_native_selection_control
    application = Zui::Application.new do
      app do
        tab_bar ["Home", { label: "Settings", icon: "gear", enabled: false }],
                id: :primary_tabs, current_index: 1, position: :bottom, spacing: 4
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "tab_bar", node.fetch("type")
    assert_equal "primary_tabs", node.fetch("id")
    assert_equal "Home", node.dig("props", "items", 0)
    assert_equal "Settings", node.dig("props", "items", 1, "label")
    assert_equal "gear", node.dig("props", "items", 1, "icon")
    assert_equal false, node.dig("props", "items", 1, "enabled")
    assert_equal 1, node.dig("props", "current_index")
    assert_equal "bottom", node.dig("props", "position")
    assert_equal 4, node.dig("props", "spacing")
  ensure
    application&.stop
  end

  def test_tab_button_is_a_typed_native_action_control
    application = Zui::Application.new do
      app do
        tab_button "Settings", id: :settings_tab, checked: true, icon: :gear,
                   shortcut: "Ctrl+2", auto_exclusive: false, width: 150
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "tab_button", node.fetch("type")
    assert_equal "settings_tab", node.fetch("id")
    assert_equal "Settings", node.dig("props", "text")
    assert_equal true, node.dig("props", "checked")
    assert_equal "gear", node.dig("props", "icon")
    assert_equal "Ctrl+2", node.dig("props", "shortcut")
    assert_equal false, node.dig("props", "auto_exclusive")
    assert_equal 150, node.dig("props", "width")
  ensure
    application&.stop
  end

  def test_page_indicator_is_a_typed_native_paging_control
    application = Zui::Application.new do
      app do
        page_indicator 5, id: :carousel_position, current_index: 2,
                          interactive: true, dot_size: 10, spacing: 6
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "page_indicator", node.fetch("type")
    assert_equal "carousel_position", node.fetch("id")
    assert_equal 5, node.dig("props", "count")
    assert_equal 2, node.dig("props", "current_index")
    assert_equal true, node.dig("props", "interactive")
    assert_equal 10, node.dig("props", "dot_size")
    assert_equal 6, node.dig("props", "spacing")
  ensure
    application&.stop
  end

  def test_stack_view_is_a_typed_native_navigation_container
    application = Zui::Application.new do
      app do
        stack_view id: :navigation_stack, current_index: 1, animated: false,
                   width: 600, height: 360 do
          page("Home") { text "Home page" }
          page("Details") { text "Details page" }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "stack_view", node.fetch("type")
    assert_equal "navigation_stack", node.fetch("id")
    assert_equal 1, node.dig("props", "current_index")
    assert_equal false, node.dig("props", "animated")
    assert_equal 600, node.dig("props", "width")
    assert_equal 360, node.dig("props", "height")
    assert_equal %w[page page], node.fetch("children").map { |child| child.fetch("type") }
    assert_equal %w[Home Details], node.fetch("children").map { |child| child.dig("props", "title") }
  ensure
    application&.stop
  end

  def test_swipe_view_is_a_typed_native_gesture_container
    application = Zui::Application.new do
      app do
        swipe_view id: :onboarding, current_index: 1, orientation: :vertical,
                   interactive: true, width: 540, height: 360 do
          page("Welcome") { text "Welcome page" }
          page("Finish") { text "Finish page" }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "swipe_view", node.fetch("type")
    assert_equal "onboarding", node.fetch("id")
    assert_equal 1, node.dig("props", "current_index")
    assert_equal "vertical", node.dig("props", "orientation")
    assert_equal true, node.dig("props", "interactive")
    assert_equal 540, node.dig("props", "width")
    assert_equal 360, node.dig("props", "height")
    assert_equal %w[Welcome Finish], node.fetch("children").map { |child| child.dig("props", "title") }
  ensure
    application&.stop
  end

  def test_drawer_is_a_typed_native_edge_popup_container
    application = Zui::Application.new do
      app do
        drawer id: :navigation_drawer, opened: true, edge: :right, modal: false,
               dim: false, close_policy: %i[escape outside], width: 320 do
          text "Navigation"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "drawer", node.fetch("type")
    assert_equal "navigation_drawer", node.fetch("id")
    assert_equal true, node.dig("props", "opened")
    assert_equal "right", node.dig("props", "edge")
    assert_equal false, node.dig("props", "modal")
    assert_equal false, node.dig("props", "dim")
    assert_equal %w[escape outside], node.dig("props", "close_policy")
    assert_equal 320, node.dig("props", "width")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_navigation_rail_is_a_typed_native_destination_control
    application = Zui::Application.new do
      app do
        navigation_rail ["Home", { label: "Settings", icon: "gear", enabled: false }],
                        id: :primary_rail, current_index: 1, extended: true,
                        alignment: :center, item_height: 60
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "navigation_rail", node.fetch("type")
    assert_equal "primary_rail", node.fetch("id")
    assert_equal "Home", node.dig("props", "items", 0)
    assert_equal "Settings", node.dig("props", "items", 1, "label")
    assert_equal "gear", node.dig("props", "items", 1, "icon")
    assert_equal false, node.dig("props", "items", 1, "enabled")
    assert_equal 1, node.dig("props", "current_index")
    assert_equal true, node.dig("props", "extended")
    assert_equal "center", node.dig("props", "alignment")
    assert_equal 60, node.dig("props", "item_height")
  ensure
    application&.stop
  end

  def test_breadcrumb_is_a_typed_native_navigation_trail
    application = Zui::Application.new do
      app do
        breadcrumb ["Home", { label: "Projects", value: 42, icon: "folder" }, "Current"],
                   id: :location, current_index: 2, separator: :chevron_right,
                   spacing: 6
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "breadcrumb", node.fetch("type")
    assert_equal "location", node.fetch("id")
    assert_equal "Home", node.dig("props", "items", 0)
    assert_equal "Projects", node.dig("props", "items", 1, "label")
    assert_equal 42, node.dig("props", "items", 1, "value")
    assert_equal "folder", node.dig("props", "items", 1, "icon")
    assert_equal 2, node.dig("props", "current_index")
    assert_equal "chevron_right", node.dig("props", "separator")
    assert_equal 6, node.dig("props", "spacing")
  ensure
    application&.stop
  end

  def test_pagination_is_a_typed_native_bounded_page_control
    application = Zui::Application.new do
      app do
        pagination 24, id: :result_pages, page: 7, sibling_count: 2,
                       show_first_last: true, previous_text: "Back", next_text: "More"
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "pagination", node.fetch("type")
    assert_equal "result_pages", node.fetch("id")
    assert_equal 24, node.dig("props", "count")
    assert_equal 7, node.dig("props", "page")
    assert_equal 2, node.dig("props", "sibling_count")
    assert_equal true, node.dig("props", "show_first_last")
    assert_equal "Back", node.dig("props", "previous_text")
    assert_equal "More", node.dig("props", "next_text")
  ensure
    application&.stop
  end

  def test_expansion_panel_is_a_typed_native_reveal_container
    application = Zui::Application.new do
      app do
        expansion_panel "Advanced", id: :advanced_panel, subtitle: "Optional settings",
                        expanded: true, duration: 180, easing: :out_cubic do
          text "Advanced content"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "expansion_panel", node.fetch("type")
    assert_equal "advanced_panel", node.fetch("id")
    assert_equal "Advanced", node.dig("props", "title")
    assert_equal "Optional settings", node.dig("props", "subtitle")
    assert_equal true, node.dig("props", "expanded")
    assert_equal 180, node.dig("props", "duration")
    assert_equal "out_cubic", node.dig("props", "easing")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_accordion_is_a_typed_native_multi_section_container
    application = Zui::Application.new do
      app do
        accordion %w[Account Network Privacy], id: :settings_accordion,
                  subtitles: ["Profile", "Connectivity", "Permissions"],
                  expanded_indices: [0, 2], multiple: true, duration: 160 do
          pane { text "Account content" }
          pane { text "Network content" }
          pane { text "Privacy content" }
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "accordion", node.fetch("type")
    assert_equal "settings_accordion", node.fetch("id")
    assert_equal %w[Account Network Privacy], node.dig("props", "titles")
    assert_equal ["Profile", "Connectivity", "Permissions"], node.dig("props", "subtitles")
    assert_equal [0, 2], node.dig("props", "expanded_indices")
    assert_equal true, node.dig("props", "multiple")
    assert_equal 160, node.dig("props", "duration")
    assert_equal %w[pane pane pane], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_tool_bar_is_a_typed_native_control_container
    application = Zui::Application.new do
      app do
        tool_bar id: :editor_tools, position: :footer, layout: :row,
                 spacing: 8, padding: 10 do
          tool_button "Save", icon: :save
          tool_button "Close", icon: :xmark
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "tool_bar", node.fetch("type")
    assert_equal "editor_tools", node.fetch("id")
    assert_equal "footer", node.dig("props", "position")
    assert_equal "row", node.dig("props", "layout")
    assert_equal 8, node.dig("props", "spacing")
    assert_equal 10, node.dig("props", "padding")
    assert_equal %w[tool_button tool_button], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_tool_separator_is_a_typed_native_toolbar_control
    application = Zui::Application.new do
      app do
        tool_separator id: :action_separator, orientation: :horizontal,
                       thickness: 2, length: 48, padding: 6, color: "#89b482"
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "tool_separator", node.fetch("type")
    assert_equal "action_separator", node.fetch("id")
    assert_equal "horizontal", node.dig("props", "orientation")
    assert_equal 2, node.dig("props", "thickness")
    assert_equal 48, node.dig("props", "length")
    assert_equal 6, node.dig("props", "padding")
    assert_equal "#89b482", node.dig("props", "color")
  ensure
    application&.stop
  end

  def test_menu_is_a_typed_native_popup_control
    application = Zui::Application.new do
      app do
        menu [
          { label: "Open", value: :open, icon: "folder" },
          { separator: true },
          { label: "Pinned", value: 7, checkable: true, checked: true },
          { label: "Disabled", enabled: false }
        ], id: :file_menu, title: "File", opened: true, x: 12, y: 24
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "menu", node.fetch("type")
    assert_equal "file_menu", node.fetch("id")
    assert_equal "File", node.dig("props", "title")
    assert_equal true, node.dig("props", "opened")
    assert_equal 12, node.dig("props", "x")
    assert_equal 24, node.dig("props", "y")
    assert_equal "open", node.dig("props", "items", 0, "value")
    assert_equal true, node.dig("props", "items", 1, "separator")
    assert_equal true, node.dig("props", "items", 2, "checkable")
    assert_equal true, node.dig("props", "items", 2, "checked")
    assert_equal false, node.dig("props", "items", 3, "enabled")
  ensure
    application&.stop
  end

  def test_menu_item_is_a_typed_native_action_control
    application = Zui::Application.new do
      app do
        menu_item "Pinned", id: :pinned_item, value: 7, icon: :pin,
                  shortcut: "Ctrl+P", checkable: true, checked: true,
                  highlighted: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "menu_item", node.fetch("type")
    assert_equal "pinned_item", node.fetch("id")
    assert_equal "Pinned", node.dig("props", "text")
    assert_equal 7, node.dig("props", "value")
    assert_equal "pin", node.dig("props", "icon")
    assert_equal "Ctrl+P", node.dig("props", "shortcut")
    assert_equal true, node.dig("props", "checkable")
    assert_equal true, node.dig("props", "checked")
    assert_equal true, node.dig("props", "highlighted")
  ensure
    application&.stop
  end

  def test_menu_separator_is_a_typed_native_menu_control
    application = Zui::Application.new do
      app do
        menu_separator id: :file_group_separator, thickness: 2,
                       width: 260, padding: 10, color: "#89b482", opacity: 0.5
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "menu_separator", node.fetch("type")
    assert_equal "file_group_separator", node.fetch("id")
    assert_equal 2, node.dig("props", "thickness")
    assert_equal 260, node.dig("props", "width")
    assert_equal 10, node.dig("props", "padding")
    assert_equal "#89b482", node.dig("props", "color")
    assert_equal 0.5, node.dig("props", "opacity")
  ensure
    application&.stop
  end

  def test_menu_bar_is_a_typed_native_hierarchical_control
    application = Zui::Application.new do
      app do
        menu_bar [
          {
            title: "File",
            items: [
              { label: "Open", value: :open, icon: "folder" },
              { separator: true },
              { label: "Quit", value: :quit }
            ]
          },
          {
            title: "View",
            items: [{ label: "Sidebar", checkable: true, checked: true }]
          }
        ], id: :main_menu, spacing: 4, height: 44
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "menu_bar", node.fetch("type")
    assert_equal "main_menu", node.fetch("id")
    assert_equal "File", node.dig("props", "menus", 0, "title")
    assert_equal "open", node.dig("props", "menus", 0, "items", 0, "value")
    assert_equal true, node.dig("props", "menus", 0, "items", 1, "separator")
    assert_equal "View", node.dig("props", "menus", 1, "title")
    assert_equal true, node.dig("props", "menus", 1, "items", 0, "checkable")
    assert_equal true, node.dig("props", "menus", 1, "items", 0, "checked")
    assert_equal 4, node.dig("props", "spacing")
    assert_equal 44, node.dig("props", "height")
  ensure
    application&.stop
  end

  def test_context_menu_is_a_typed_native_targeted_popup
    application = Zui::Application.new do
      app do
        target = button "Document", id: :document
        context_menu [
          { label: "Copy", value: :copy, icon: "copy" },
          { separator: true },
          { label: "Delete", value: :delete, enabled: false }
        ], id: :document_menu, target: target, opened: false,
           activation_width: 240, activation_height: 80
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 1)

    assert_equal "context_menu", node.fetch("type")
    assert_equal "document_menu", node.fetch("id")
    assert_equal "document", node.dig("props", "target")
    assert_equal false, node.dig("props", "opened")
    assert_equal 240, node.dig("props", "activation_width")
    assert_equal 80, node.dig("props", "activation_height")
    assert_equal "copy", node.dig("props", "items", 0, "value")
    assert_equal true, node.dig("props", "items", 1, "separator")
    assert_equal false, node.dig("props", "items", 2, "enabled")
  ensure
    application&.stop
  end

  def test_popup_is_a_typed_native_content_container
    application = Zui::Application.new do
      app do
        popup id: :details_popup, opened: true, x: 24, y: 36,
              modal: true, dim: true, layout: :column, spacing: 10,
              animated: true, duration: 180, easing: :out_cubic do
          text "Popup content"
          button "Done"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "popup", node.fetch("type")
    assert_equal "details_popup", node.fetch("id")
    assert_equal true, node.dig("props", "opened")
    assert_equal 24, node.dig("props", "x")
    assert_equal 36, node.dig("props", "y")
    assert_equal true, node.dig("props", "modal")
    assert_equal "column", node.dig("props", "layout")
    assert_equal 180, node.dig("props", "duration")
    assert_equal "out_cubic", node.dig("props", "easing")
    assert_equal %w[text button], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_dialog_is_a_typed_native_standard_button_container
    application = Zui::Application.new do
      app do
        dialog "Save changes?", id: :save_dialog, opened: true,
               centered: true,
               standard_buttons: %i[save discard cancel], modal: true,
               width: 500, height: 300 do
          text "Choose how to continue."
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "dialog", node.fetch("type")
    assert_equal "save_dialog", node.fetch("id")
    assert_equal "Save changes?", node.dig("props", "title")
    assert_equal true, node.dig("props", "opened")
    assert_equal true, node.dig("props", "centered")
    assert_equal %w[save discard cancel], node.dig("props", "standard_buttons")
    assert_equal true, node.dig("props", "modal")
    assert_equal 500, node.dig("props", "width")
    assert_equal 300, node.dig("props", "height")
    assert_equal "text", node.dig("children", 0, "type")
  ensure
    application&.stop
  end

  def test_alert_dialog_is_a_typed_native_severity_control
    application = Zui::Application.new do
      app do
        alert_dialog "Connection failed", "The server could not be reached.",
                     id: :connection_alert, severity: :error, opened: true,
                     centered: true,
                     informative_text: "Check the network and retry.",
                     detailed_text: "ECONNREFUSED 127.0.0.1:443",
                     standard_buttons: %i[retry cancel]
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "alert_dialog", node.fetch("type")
    assert_equal "connection_alert", node.fetch("id")
    assert_equal "Connection failed", node.dig("props", "title")
    assert_equal "The server could not be reached.", node.dig("props", "message")
    assert_equal "error", node.dig("props", "severity")
    assert_equal true, node.dig("props", "opened")
    assert_equal true, node.dig("props", "centered")
    assert_equal "Check the network and retry.", node.dig("props", "informative_text")
    assert_equal "ECONNREFUSED 127.0.0.1:443", node.dig("props", "detailed_text")
    assert_equal %w[retry cancel], node.dig("props", "standard_buttons")
  ensure
    application&.stop
  end

  def test_message_dialog_is_a_typed_platform_native_control
    application = Zui::Application.new do
      app do
        message_dialog "Unsaved changes", "Save before closing?",
                       id: :save_prompt, opened: true,
                       informative_text: "Your latest edits are not on disk.",
                       detailed_text: "Document: notes.txt",
                       buttons: %i[save discard cancel], modality: :window
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "message_dialog", node.fetch("type")
    assert_equal "save_prompt", node.fetch("id")
    assert_equal "Unsaved changes", node.dig("props", "title")
    assert_equal "Save before closing?", node.dig("props", "message")
    assert_equal "Your latest edits are not on disk.", node.dig("props", "informative_text")
    assert_equal "Document: notes.txt", node.dig("props", "detailed_text")
    assert_equal %w[save discard cancel], node.dig("props", "buttons")
    assert_equal "window", node.dig("props", "modality")
    assert_equal true, node.dig("props", "opened")
  ensure
    application&.stop
  end

  def test_bottom_sheet_is_a_typed_reactive_content_container
    application = Zui::Application.new do
      app do
        bottom_sheet id: :actions, opened: true, height: 280, max_width: 640,
                     dismiss_threshold: 0.4, draggable: true, layout: :column do
          text "Choose an action"
          button "Continue", id: :continue
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "bottom_sheet", node.fetch("type")
    assert_equal "actions", node.fetch("id")
    assert_equal true, node.dig("props", "opened")
    assert_equal 280, node.dig("props", "height")
    assert_equal 640, node.dig("props", "max_width")
    assert_equal 0.4, node.dig("props", "dismiss_threshold")
    assert_equal true, node.dig("props", "draggable")
    assert_equal "column", node.dig("props", "layout")
    assert_equal %w[text button], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_modal_sheet_is_a_typed_reactive_content_container
    application = Zui::Application.new do
      app do
        modal_sheet "Account settings", id: :settings_sheet, opened: true,
                    edge: :left, width: 460, max_height: 780,
                    show_close: true, dismissible: true do
          text "Profile"
          text_field "Ada"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "modal_sheet", node.fetch("type")
    assert_equal "settings_sheet", node.fetch("id")
    assert_equal "Account settings", node.dig("props", "title")
    assert_equal true, node.dig("props", "opened")
    assert_equal "left", node.dig("props", "edge")
    assert_equal 460, node.dig("props", "width")
    assert_equal 780, node.dig("props", "max_height")
    assert_equal true, node.dig("props", "show_close")
    assert_equal true, node.dig("props", "dismissible")
    assert_equal %w[text text_field], node.fetch("children").map { |child| child.fetch("type") }
  ensure
    application&.stop
  end

  def test_snackbar_is_a_typed_timed_feedback_control
    application = Zui::Application.new do
      app do
        snackbar "Changes saved", id: :saved_notice, opened: true,
                 action_text: "Undo", duration: 6500,
                 position: :top_right, pause_on_hover: true,
                 close_on_action: false
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "snackbar", node.fetch("type")
    assert_equal "saved_notice", node.fetch("id")
    assert_equal "Changes saved", node.dig("props", "message")
    assert_equal true, node.dig("props", "opened")
    assert_equal "Undo", node.dig("props", "action_text")
    assert_equal 6500, node.dig("props", "duration")
    assert_equal "top_right", node.dig("props", "position")
    assert_equal true, node.dig("props", "pause_on_hover")
    assert_equal false, node.dig("props", "close_on_action")
  ensure
    application&.stop
  end

  def test_banner_is_a_typed_severity_feedback_control
    application = Zui::Application.new do
      app do
        banner "A newer version is available.", id: :update_banner,
               title: "Update ready", severity: :success,
               action_text: "Install", dismissible: true,
               width: 720, icon: :download
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "banner", node.fetch("type")
    assert_equal "update_banner", node.fetch("id")
    assert_equal "A newer version is available.", node.dig("props", "message")
    assert_equal "Update ready", node.dig("props", "title")
    assert_equal "success", node.dig("props", "severity")
    assert_equal "Install", node.dig("props", "action_text")
    assert_equal true, node.dig("props", "dismissible")
    assert_equal 720, node.dig("props", "width")
    assert_equal "download", node.dig("props", "icon")
  ensure
    application&.stop
  end

  def test_toast_is_a_typed_timed_severity_control
    application = Zui::Application.new do
      app do
        toast "The export has completed.", id: :export_toast,
              title: "Export ready", severity: :success,
              opened: true, duration: 5000, position: :bottom_left,
              pause_on_hover: true, dismiss_on_click: false
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "toast", node.fetch("type")
    assert_equal "export_toast", node.fetch("id")
    assert_equal "The export has completed.", node.dig("props", "message")
    assert_equal "Export ready", node.dig("props", "title")
    assert_equal "success", node.dig("props", "severity")
    assert_equal true, node.dig("props", "opened")
    assert_equal 5000, node.dig("props", "duration")
    assert_equal "bottom_left", node.dig("props", "position")
    assert_equal true, node.dig("props", "pause_on_hover")
    assert_equal false, node.dig("props", "dismiss_on_click")
  ensure
    application&.stop
  end

  def test_busy_indicator_is_a_typed_native_activity_control
    application = Zui::Application.new do
      app do
        busy_indicator false, id: :sync_spinner, width: 36, height: 36,
                              color: "#8ec07c", opacity: 0.8,
                              accessible_name: "Synchronizing account"
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "busy_indicator", node.fetch("type")
    assert_equal "sync_spinner", node.fetch("id")
    assert_equal false, node.dig("props", "running")
    assert_equal 36, node.dig("props", "width")
    assert_equal 36, node.dig("props", "height")
    assert_equal "#8ec07c", node.dig("props", "color")
    assert_equal 0.8, node.dig("props", "opacity")
    assert_equal "Synchronizing account", node.dig("props", "accessible_name")
  ensure
    application&.stop
  end

  def test_progress_ring_supports_determinate_and_default_indeterminate_modes
    application = Zui::Application.new do
      app do
        progress_ring 75, id: :upload_progress, minimum: 0, maximum: 100,
                          size: 80, thickness: 7, show_label: true,
                          label_format: "{percent}% uploaded", clockwise: false
        progress_ring id: :waiting_progress
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    nodes = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children")
    determinate, indeterminate = nodes

    assert_equal "progress_ring", determinate.fetch("type")
    assert_equal "upload_progress", determinate.fetch("id")
    assert_equal 75, determinate.dig("props", "value")
    assert_equal 0, determinate.dig("props", "minimum")
    assert_equal 100, determinate.dig("props", "maximum")
    assert_equal 80, determinate.dig("props", "size")
    assert_equal 7, determinate.dig("props", "thickness")
    assert_equal true, determinate.dig("props", "show_label")
    assert_equal "{percent}% uploaded", determinate.dig("props", "label_format")
    assert_equal false, determinate.dig("props", "clockwise")
    assert_equal "progress_ring", indeterminate.fetch("type")
    assert_equal true, indeterminate.dig("props", "indeterminate")
    refute indeterminate.fetch("props").key?("value")
  ensure
    application&.stop
  end

  def test_skeleton_is_a_typed_multivariant_loading_placeholder
    application = Zui::Application.new do
      app do
        skeleton id: :avatar_placeholder, variant: :circle, width: 72, height: 72,
                 animated: false
        skeleton id: :copy_placeholder, variant: :text, width: 360,
                 lines: 4, line_height: 16, spacing: 10,
                 last_line_width: 0.5, direction: :right_to_left
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    nodes = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children")
    avatar, copy = nodes

    assert_equal "skeleton", avatar.fetch("type")
    assert_equal "avatar_placeholder", avatar.fetch("id")
    assert_equal "circle", avatar.dig("props", "variant")
    assert_equal 72, avatar.dig("props", "width")
    assert_equal 72, avatar.dig("props", "height")
    assert_equal false, avatar.dig("props", "animated")
    assert_equal "skeleton", copy.fetch("type")
    assert_equal "text", copy.dig("props", "variant")
    assert_equal 4, copy.dig("props", "lines")
    assert_equal 16, copy.dig("props", "line_height")
    assert_equal 10, copy.dig("props", "spacing")
    assert_equal 0.5, copy.dig("props", "last_line_width")
    assert_equal "right_to_left", copy.dig("props", "direction")
  ensure
    application&.stop
  end

  def test_item_delegate_is_a_typed_native_collection_row
    application = Zui::Application.new do
      app do
        item_delegate "Downloads", id: :downloads_item, value: :downloads,
                      description: "12 files", icon: :download,
                      trailing_text: "2.4 GB", selected: true,
                      checkable: true, checked: true, show_indicator: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "item_delegate", node.fetch("type")
    assert_equal "downloads_item", node.fetch("id")
    assert_equal "Downloads", node.dig("props", "text")
    assert_equal "downloads", node.dig("props", "value")
    assert_equal "12 files", node.dig("props", "description")
    assert_equal "download", node.dig("props", "icon")
    assert_equal "2.4 GB", node.dig("props", "trailing_text")
    assert_equal true, node.dig("props", "selected")
    assert_equal true, node.dig("props", "checkable")
    assert_equal true, node.dig("props", "checked")
    assert_equal true, node.dig("props", "show_indicator")
  ensure
    application&.stop
  end

  def test_check_delegate_is_a_typed_native_tristate_collection_row
    application = Zui::Application.new do
      app do
        check_delegate "Select visible files", id: :visible_files, value: :visible,
                       description: "Some files are already selected",
                       tristate: true, check_state: :partial,
                       indicator_size: 24, selected: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "check_delegate", node.fetch("type")
    assert_equal "visible_files", node.fetch("id")
    assert_equal "Select visible files", node.dig("props", "text")
    assert_equal "visible", node.dig("props", "value")
    assert_equal "Some files are already selected", node.dig("props", "description")
    assert_equal true, node.dig("props", "tristate")
    assert_equal "partial", node.dig("props", "check_state")
    assert_equal 24, node.dig("props", "indicator_size")
    assert_equal true, node.dig("props", "selected")
  ensure
    application&.stop
  end

  def test_radio_delegate_is_a_typed_native_exclusive_collection_row
    application = Zui::Application.new do
      app do
        column do
          radio_delegate "Compact", id: :compact_density, value: :compact,
                         description: "More rows on screen", checked: true,
                         auto_exclusive: true, indicator_size: 24, dot_size: 10
          radio_delegate "Comfortable", id: :comfortable_density, value: :comfortable,
                         description: "More room around each row"
        end
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    nodes = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0, "children")
    compact, comfortable = nodes

    assert_equal "radio_delegate", compact.fetch("type")
    assert_equal "compact_density", compact.fetch("id")
    assert_equal "Compact", compact.dig("props", "text")
    assert_equal "compact", compact.dig("props", "value")
    assert_equal "More rows on screen", compact.dig("props", "description")
    assert_equal true, compact.dig("props", "checked")
    assert_equal true, compact.dig("props", "auto_exclusive")
    assert_equal 24, compact.dig("props", "indicator_size")
    assert_equal 10, compact.dig("props", "dot_size")
    assert_equal "radio_delegate", comfortable.fetch("type")
    assert_equal "comfortable", comfortable.dig("props", "value")
  ensure
    application&.stop
  end

  def test_switch_delegate_is_a_typed_native_toggle_collection_row
    application = Zui::Application.new do
      app do
        switch_delegate "Automatic updates", id: :automatic_updates,
                        value: :automatic_updates, checked: true,
                        description: "Install security updates automatically",
                        indicator_width: 48, indicator_height: 26,
                        thumb_size: 20, animated: true, duration: 180
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "switch_delegate", node.fetch("type")
    assert_equal "automatic_updates", node.fetch("id")
    assert_equal "Automatic updates", node.dig("props", "text")
    assert_equal "automatic_updates", node.dig("props", "value")
    assert_equal true, node.dig("props", "checked")
    assert_equal "Install security updates automatically", node.dig("props", "description")
    assert_equal 48, node.dig("props", "indicator_width")
    assert_equal 26, node.dig("props", "indicator_height")
    assert_equal 20, node.dig("props", "thumb_size")
    assert_equal true, node.dig("props", "animated")
    assert_equal 180, node.dig("props", "duration")
  ensure
    application&.stop
  end

  def test_swipe_delegate_is_a_typed_native_action_row
    application = Zui::Application.new do
      app do
        swipe_delegate "Quarterly report", id: :quarterly_report, value: 42,
                       description: "Edited 2 hours ago", icon: :file,
                       left_action: "Archive", left_value: :archive,
                       left_icon: :folder, left_color: "#458588",
                       right_action: "Delete", right_value: :delete,
                       right_icon: :trash, right_color: "#cc241d",
                       opened_side: :left, action_width: 110,
                       close_on_action: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "swipe_delegate", node.fetch("type")
    assert_equal "quarterly_report", node.fetch("id")
    assert_equal "Quarterly report", node.dig("props", "text")
    assert_equal 42, node.dig("props", "value")
    assert_equal "Edited 2 hours ago", node.dig("props", "description")
    assert_equal "Archive", node.dig("props", "left_action")
    assert_equal "archive", node.dig("props", "left_value")
    assert_equal "Delete", node.dig("props", "right_action")
    assert_equal "delete", node.dig("props", "right_value")
    assert_equal "left", node.dig("props", "opened_side")
    assert_equal 110, node.dig("props", "action_width")
    assert_equal true, node.dig("props", "close_on_action")
  ensure
    application&.stop
  end

  def test_grid_view_is_a_typed_native_virtualized_collection
    items = [
      { id: 1, name: "Documents", detail: "24 files", glyph: :folder },
      { id: 2, name: "Pictures", detail: "81 files", glyph: :image }
    ]
    application = Zui::Application.new do
      app do
        grid_view items, id: :folders, key_field: :id, label_field: :name,
                         description_field: :detail, icon_field: :glyph,
                         selected: 2, cell_width: 180, cell_height: 132,
                         flow: :left_to_right, layout_direction: :right_to_left,
                         snap_mode: :row, key_navigation_wraps: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "grid_view", node.fetch("type")
    assert_equal "folders", node.fetch("id")
    assert_equal 2, node.dig("props", "items").length
    assert_equal "id", node.dig("props", "key_field")
    assert_equal "name", node.dig("props", "label_field")
    assert_equal "detail", node.dig("props", "description_field")
    assert_equal "glyph", node.dig("props", "icon_field")
    assert_equal 2, node.dig("props", "selected")
    assert_equal 180, node.dig("props", "cell_width")
    assert_equal 132, node.dig("props", "cell_height")
    assert_equal "right_to_left", node.dig("props", "layout_direction")
    assert_equal "row", node.dig("props", "snap_mode")
    assert_equal true, node.dig("props", "key_navigation_wraps")
  ensure
    application&.stop
  end

  def test_table_view_is_a_typed_arbitrary_column_native_table
    rows = [
      { name: "Ada", role: "Engineer", active: true },
      { name: "Grace", role: "Scientist", active: false }
    ]
    columns = [
      { key: :name, label: "Name", width: 180, editable: true },
      { key: :role, label: "Role", width: 220 },
      { key: :active, label: "Active", width: 100, alignment: :center, editable: false }
    ]
    application = Zui::Application.new do
      app do
        table_view rows, id: :people_table, columns: columns,
                         selected_row: 1, selected_column: 0,
                         selection_behavior: :rows, selection_mode: :extended,
                         editable: true, edit_triggers: %i[double_tap edit_key],
                         alternating_rows: true, row_height: 46
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "table_view", node.fetch("type")
    assert_equal "people_table", node.fetch("id")
    assert_equal 2, node.dig("props", "rows").length
    assert_equal 3, node.dig("props", "columns").length
    assert_equal "name", node.dig("props", "columns", 0, "key")
    assert_equal "Name", node.dig("props", "columns", 0, "label")
    assert_equal 180, node.dig("props", "columns", 0, "width")
    assert_equal 1, node.dig("props", "selected_row")
    assert_equal 0, node.dig("props", "selected_column")
    assert_equal "rows", node.dig("props", "selection_behavior")
    assert_equal "extended", node.dig("props", "selection_mode")
    assert_equal true, node.dig("props", "editable")
    assert_equal %w[double_tap edit_key], node.dig("props", "edit_triggers")
    assert_equal true, node.dig("props", "alternating_rows")
    assert_equal 46, node.dig("props", "row_height")
  ensure
    application&.stop
  end

  def test_tree_view_is_a_typed_hierarchical_native_tree
    rows = [
      {
        name: "Source", kind: "folder",
        children: [
          { name: "app.rb", kind: "file", children: [] },
          { name: "components", kind: "folder", children: [{ name: "card.rb", kind: "file" }] }
        ]
      }
    ]
    columns = [
      { key: :name, label: "Name", width: 280, editable: true },
      { key: :kind, label: "Kind", width: 120, alignment: :center, editable: false }
    ]
    application = Zui::Application.new do
      app do
        tree_view rows, id: :source_tree, columns: columns, children_field: :children,
                        selected_path: [0, 1], selected_column: 0,
                        expanded_paths: [[0], [0, 1]], expand_depth: 2,
                        selection_behavior: :rows, editable: true
      end
    end
    output = StringIO.new
    application.start(output: output, error: StringIO.new)
    node = messages(output).find { |message| message["type"] == "render" }
      .dig("surfaces", "main", "children", 0)

    assert_equal "tree_view", node.fetch("type")
    assert_equal "source_tree", node.fetch("id")
    assert_equal "children", node.dig("props", "children_field")
    assert_equal "Source", node.dig("props", "rows", 0, "name")
    assert_equal "components", node.dig("props", "rows", 0, "children", 1, "name")
    assert_equal "name", node.dig("props", "columns", 0, "key")
    assert_equal [0, 1], node.dig("props", "selected_path")
    assert_equal [[0], [0, 1]], node.dig("props", "expanded_paths")
    assert_equal 2, node.dig("props", "expand_depth")
    assert_equal true, node.dig("props", "editable")
  ensure
    application&.stop
  end

  def test_animation_sequences_accumulate_track_delays
    app = Zui::Application.new do
      panel :main do
        label = text "Pulse", id: :label
        button("Pulse", id: :pulse) do
          animate_sequence label, [
            { to: { scale: 1.2 }, duration: 100, easing: :out_quad },
            { to: { scale: 1.0 }, duration: 150, easing: :in_quad, pause: 25 }
          ]
        end
      end
    end
    output = StringIO.new
    app.start(output: output, error: StringIO.new)
    output.truncate(0)
    output.rewind
    app.receive(event("pulse", surface: "main"))
    tracks = messages(output).first.fetch("tracks")
    assert_equal [0, 100], tracks.map { |track| track.fetch("delay") }
    assert_equal [1.0, 1.2], tracks.map { |track| track.fetch("from") }
  end

  def test_every_builtin_component_has_a_named_ruby_builder
    missing = Zui::COMPONENTS.keys.reject do |component_name|
      Zui::Builder.public_instance_methods.include?(component_name)
    end

    assert_empty missing
    assert_operator Zui::COMPONENTS.length, :>=, 241
  end

  def test_gpu_animation_multimedia_and_model_builders_serialize_node_references
    application = Zui::Application.new do
      app do
        target = rectangle id: :target, width: 160, height: 90
        shader_effect :wave, id: :shader, running: true, frequency: 2.5 do
          text "GPU content"
        end
        multi_effect id: :effect, blur_enabled: true, blur: 0.4 do
          text "Effect source"
        end
        particle_system id: :particles, emit_rate: 24, life_span: 900
        number_animation target, id: :fade, property: :opacity, from: 0, to: 1, running: true
        parallel_animation [{ type: :number, target: target, property: :scale, from: 0.8, to: 1.0 }], id: :group
        state :active, target: target, id: :active_state, properties: { opacity: 1 }, revision: 1
        media_player "intro.ogg", id: :player, auto_play: false
        video_output :player, id: :output
        capture_session id: :capture do
          text "Capture preview"
        end
        list_model [{ id: 1, name: "Ruby" }], id: :model, revision: 1
        sort_filter_proxy_model [{ name: "Ruby" }], id: :proxy, filter_field: :name, sort_field: :name
        clipboard "copied", id: :clipboard
      end
    end

    children = application.tree.dig("main", "children")
    by_id = children.to_h { |node| [node.fetch("id"), node] }
    assert_equal "target", by_id.dig("fade", "props", "target")
    assert_equal "target", by_id.dig("group", "props", "animations", 0, "target")
    assert_equal "target", by_id.dig("active_state", "props", "target")
    assert_equal "player", by_id.dig("output", "props", "source")
    assert_equal "wave", by_id.dig("shader", "props", "fragment_shader")
    assert_equal true, by_id.dig("effect", "props", "blur_enabled")
    assert_equal "Ruby", by_id.dig("model", "props", "items", 0, "name")
    assert_equal "copied", by_id.dig("clipboard", "props", "text")
  end

  def test_mobile_service_and_content_builders_serialize_native_qml_payloads
    application = Zui::Application.new do
      app do
        safe_area id: :safe, edges: %i[top bottom] do
          map id: :campus, plugin: :osm, latitude: 37.3349, longitude: -122.0090 do
            map_marker id: :office, latitude: 37.3349, longitude: -122.0090 do
              text "Office"
            end
            map_polyline [[37.3349, -122.0090], [37.3317, -122.0301]], id: :route
          end
        end
        camera_permission id: :camera_access, auto_request: true
        accelerometer id: :motion, active: true, data_rate: 30
        position_source id: :position, active: true, preferred_methods: %i[satellite non_satellite]
        geocode_model "Apple Park", id: :geocoder, plugin: :osm
        route_model [[37.3349, -122.0090], [37.3317, -122.0301]], id: :directions
        text_to_speech "Welcome", id: :speech
        web_view "https://example.test", id: :browser, visible: false
        web_socket "wss://example.test/socket", id: :socket
        lottie_animation "assets/loader.json", id: :loader
        pdf_view "assets/guide.pdf", id: :guide
      end
    end

    children = application.tree.dig("main", "children")
    by_id = children.to_h { |node| [node.fetch("id"), node] }
    map_node = by_id.dig("safe", "children", 0)
    assert_equal "map", map_node.fetch("type")
    assert_equal "osm", map_node.dig("props", "plugin")
    assert_equal "Office", map_node.dig("children", 0, "children", 0, "props", "text")
    assert_equal [[37.3349, -122.0090], [37.3317, -122.0301]], map_node.dig("children", 1, "props", "path")
    assert_equal true, by_id.dig("camera_access", "props", "auto_request")
    assert_equal 30, by_id.dig("motion", "props", "data_rate")
    assert_equal %w[satellite non_satellite], by_id.dig("position", "props", "preferred_methods")
    assert_equal "Apple Park", by_id.dig("geocoder", "props", "query")
    assert_equal 2, by_id.dig("directions", "props", "waypoints").length
    assert_equal true, by_id.dig("speech", "props", "auto_speak")
    assert_equal "https://example.test", by_id.dig("browser", "props", "url")
    assert_equal "wss://example.test/socket", by_id.dig("socket", "props", "url")
    assert_equal "assets/loader.json", by_id.dig("loader", "props", "source")
    assert_equal "assets/guide.pdf", by_id.dig("guide", "props", "source")
  end
end
