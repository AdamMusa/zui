# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QmlContractTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def source(name)
    contents = File.read(File.join(ROOT, name))
    return contents unless name == "ControlNode.qml"

    extracted = Dir[File.join(ROOT, "Components", "Builtins", "*.qml")].sort.map do |path|
      File.read(path)
        .gsub(/\brenderer\./, "root.")
        .gsub("root.childDelegateComponent", "childDelegate")
        .gsub("root.rowChildDelegateComponent", "rowChildDelegate")
        .gsub("root.columnChildDelegateComponent", "columnChildDelegate")
        .gsub("root.layoutChildDelegateComponent", "layoutChildDelegate")
        .gsub("root.splitChildDelegateComponent", "splitChildDelegate")
        .gsub('../../ControlNode.qml', 'ControlNode.qml')
    end
    ([contents] + extracted).join("\n")
  end

  def test_each_builtin_renderer_lives_in_its_own_qml_file
    router = File.read(File.join(ROOT, "ControlNode.qml"))
    renderer_names = router.scan(/Builtins\.(\w+) \{ renderer: root \}/).flatten

    assert_equal renderer_names.uniq.sort, renderer_names.sort
    assert_includes router, "function builtInSource(typeName)"
    assert_includes router, "builtInSource(node.type)"

    Zui::COMPONENTS.each_key do |component_name|
      name = component_name.to_s.split("_").map(&:capitalize).join
      path = File.join(ROOT, "Components", "Builtins", "#{name}.qml")
      assert File.file?(path), "missing #{path}"
      assert_match(/(?:(?:required\s+)?property var renderer|renderer:\s*null)/, File.read(path), "#{path} does not expose its renderer bridge")
    end
    refute_includes router, "QQC.Button {"
    refute_includes router, "OmarchyUi.WidgetButton {"
  end

  def test_every_qml_property_read_is_declared_in_its_ruby_schema
    common = Zui::ComponentRegistry::ITEM_PROPERTIES.map(&:to_s)
    undeclared = {}

    Zui::COMPONENTS.each do |component_name, (properties, _events, _container)|
      adapter_name = component_name.to_s.split("_").map(&:capitalize).join
      qml = File.read(File.join(ROOT, "Components", "Builtins", "#{adapter_name}.qml"))
      property_reads = qml.scan(/(?:renderer|root)\.prop\(\s*["']([^"']+)["']/).flatten.uniq
      missing = property_reads - properties.map(&:to_s) - common
      undeclared[component_name] = missing unless missing.empty?
    end

    assert_empty undeclared
  end

  def test_gpu_adapters_ship_native_effects_particles_and_precompiled_shaders
    shader = source("Components/Builtins/ShaderEffect.qml")
    effect = source("Components/Builtins/MultiEffect.qml")
    particles = source("Components/Builtins/ParticleSystem.qml")

    assert_includes shader, "ShaderEffect {"
    assert_includes shader, ".frag.qsb"
    assert_includes effect, "MultiEffect {"
    assert_includes particles, "ParticleSystem {"
    assert_includes particles, "Emitter {"
    %w[passthrough grayscale wave pixelate vignette].each do |name|
      path = File.join(ROOT, "Components", "Builtins", "Shaders", "#{name}.frag.qsb")
      assert_operator File.size(path), :>, 100, "invalid precompiled shader: #{path}"
    end
  end

  def test_component_coverage_catalog_has_no_unimplemented_entries
    coverage = File.read(File.join(ROOT, "docs", "component-coverage.md"))

    refute_match(/^- \[ \] /, coverage)
  end

  def test_service_uses_one_injected_bidirectional_transport
    qml = source("Service.qml")
    native = source("native/ZuiProcess.cpp")
    assert_includes qml, "required property var transport"
    assert_includes qml, "transport.write(JSON.stringify("
    assert_includes qml, "transport.start(runtimeExecutable, program, projectDir, rubyLoadPath)"
    assert_includes qml, "function onLineReceived(line)"
    assert_includes native, "QProcess::SeparateChannels"
    assert_includes native, "m_process.write(data.toUtf8())"
    refute_includes qml, "Quickshell"
    refute_includes qml, "Process {"
  end

  def test_service_applies_reactive_patch_batches_with_one_visual_revision
    qml = source("Service.qml")

    assert_includes qml, 'message.op === "batch"'
    assert_includes qml, "validSetPatch(message.patches[batchIndex])"
    assert_includes qml, "applySetPatch(message.patches[applyIndex], false)"
  end

  def test_framework_loads_bundled_cross_platform_text_and_icon_fonts
    fonts = source("Theme/Fonts.qml")
    style = source("Theme/Style.qml")
    renderer = source("ControlNode.qml")
    framework_qml = (Dir[File.join(ROOT, "*.qml")] +
      Dir[File.join(ROOT, "{Components,Controls,Theme}", "**", "*.qml")]).map { File.read(_1) }.join("\n")

    %w[RobotoMono-Regular.otf RobotoMono-Bold.otf FontAwesome-Solid.otf FontAwesome-Brands.otf].each do |name|
      assert_operator File.size(File.join(ROOT, "Fonts", name)), :>, 10_000
    end
    assert_includes fonts, "readonly property bool ready:"
    assert_includes style, "readonly property string family: Fonts.family"
    assert_includes renderer, "readonly property string iconFontFamily: Fonts.iconFamily"
    refute_match(/Sans ?Serif/, framework_qml)
  end

  def test_renderer_installs_the_ruby_component_registry
    qml = source("Service.qml")
    assert_includes qml, "function validateComponents(components)"
    assert_includes qml, "componentDefinitions = validated"
    assert_includes qml, "allowedTypes = dynamicTypes"
    assert_includes qml, "allowedProperties = dynamicProperties"
    assert_includes qml, "propertyMap: definition.property_map"
    assert_includes qml, "eventMap: definition.event_map"
  end

  def test_round_button_has_a_specific_native_checkable_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "round_button"'
    assert_includes renderer, "id: roundButtonComponent"
    assert_includes renderer, "QQC.RoundButton {"
    assert_includes renderer, '"change", { value: checked }'
  end

  def test_tool_button_has_a_specific_native_toolbar_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tool_button"'
    assert_includes renderer, "id: toolButtonComponent"
    assert_includes renderer, "QQC.ToolButton {"
    assert_includes renderer, 'nativeToolButton.hovered ? Color.popups.background'
  end

  def test_delay_button_has_a_specific_native_hold_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "delay_button"'
    assert_includes renderer, "id: delayButtonComponent"
    assert_includes renderer, "QQC.DelayButton {"
    assert_includes renderer, '"activate", {}'
    assert_includes renderer, '"progress", { value: progress }'
  end

  def test_native_qml_bridge_maps_properties_events_children_and_animations
    qml = source("ControlNode.qml")
    assert_includes qml, "function syncNativeProperties()"
    assert_includes qml, "function connectNativeEvents()"
    assert_includes qml, "definition.propertyMap[transition.property]"
    assert_includes qml, 'hasOwnProperty("contentHost")'
    assert_includes qml, "delegate: childDelegate"
  end

  def test_application_surface_is_a_standard_qt_application_window
    qml = source("Desktop.qml")
    assert_includes qml, "QQC.ApplicationWindow {"
    assert_includes qml, "transport: zuiProcess"
    refute_includes qml, "FloatingWindow {"
    refute_includes qml, "PanelWindow {"
    refute_includes qml, "WlrLayershell"
    assert_includes qml, 'option("title"'
    assert_includes qml, 'option("min_width"'
  end

  def test_renderer_supports_validated_native_property_animations
    renderer = source("ControlNode.qml")
    service = source("Service.qml")
    assert_includes renderer, "id: propertyAnimationFactory"
    assert_includes renderer, "function easingType(name)"
    assert_includes service, 'return reject("patch animation rejected")'
    assert_includes service, "replacement.transition"
  end

  def test_component_lifecycle_events_require_explicit_subscriptions
    renderer = source("ControlNode.qml")
    service = source("Service.qml")
    assert_includes renderer, 'subscribed("mount")'
    assert_includes renderer, 'subscribed("unmount")'
    assert_includes service, "subscriptions.indexOf(eventName) < 0"
  end

  def test_renderer_uses_runtime_recursion_and_qualified_zui_types
    renderer = source("ControlNode.qml")
    card = source("Components/Builtins/Card.qml")
    refute_match(/^\s+ControlNode \{$/, renderer)
    assert_includes renderer, 'source: Qt.resolvedUrl("ControlNode.qml")'
    assert_includes card, "ZuiControls.BorderSurface {"
    refute_includes renderer, "OmarchyUi"
  end

  def test_aspect_ratio_has_a_specific_reactive_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "aspect_ratio"'
    assert_includes renderer, "id: aspectRatioComponent"
    assert_includes renderer, 'Number(requestedWidth) / aspect'
    assert_includes renderer, "Repeater { model: root.node.children || []; delegate: childDelegate }"
  end

  def test_constrained_box_has_a_specific_bounded_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "constrained_box"'
    assert_includes renderer, "id: constrainedBoxComponent"
    assert_includes renderer, 'root.prop("min_width", 0)'
    assert_includes renderer, 'root.prop("max_height", Number.MAX_VALUE)'
  end

  def test_fitted_box_has_a_specific_scaling_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "fitted_box"'
    assert_includes renderer, "id: fittedBoxComponent"
    assert_includes renderer, 'fitMode === "cover"'
    assert_includes renderer, "Scale { xScale: fittedXScale; yScale: fittedYScale }"
  end

  def test_wrap_has_a_specific_responsive_flow_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "wrap"'
    assert_includes renderer, "id: wrapComponent"
    assert_includes renderer, 'root.prop("layout_direction", "left_to_right")'
    assert_includes renderer, "Flow.TopToBottom : Flow.LeftToRight"
  end

  def test_split_view_has_a_specific_native_resizable_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "split_view"'
    assert_includes renderer, "id: splitViewComponent"
    assert_includes renderer, "QQC.SplitView {"
    assert_includes renderer, '"resize", { sizes: currentSizes() }'
    assert_includes renderer, "QQC.SplitView.preferredWidth"
  end

  def test_stack_layout_has_a_specific_native_indexed_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "stack_layout"'
    assert_includes renderer, "id: stackLayoutComponent"
    assert_includes renderer, "StackLayout {"
    assert_includes renderer, 'root.prop("current_index", 0)'
  end

  def test_layout_item_proxy_has_a_specific_native_layout_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "layout_item_proxy"'
    assert_includes renderer, "id: layoutItemProxyComponent"
    assert_includes renderer, "LayoutItemProxy {"
    assert_includes renderer, "root.findRenderedItem(targetId)"
    assert_includes renderer, "Layout.preferredWidth"
    assert_includes renderer, '"target_change", {'
  end

  def test_window_has_a_specific_native_secondary_window_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "window"'
    assert_includes renderer, "id: windowComponent"
    assert_includes renderer, "Window {"
    assert_includes renderer, 'root.prop("modality", "none")'
    assert_includes renderer, 'root.prop("flags", "window")'
    assert_includes renderer, '"close", {'
    assert_includes renderer, "delegate: childDelegate"
  end

  def test_application_window_has_a_specific_controls_window_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "application_window"'
    assert_includes renderer, "id: applicationWindowComponent"
    assert_includes renderer, "QQC.ApplicationWindow {"
    assert_includes renderer, 'root.prop("background", "transparent")'
    assert_includes renderer, "onActiveFocusControlChanged"
    assert_includes renderer, '"focus_change", {'
    assert_includes renderer, "delegate: childDelegate"
  end

  def test_loader_has_a_specific_lazy_native_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "loader"'
    assert_includes renderer, "id: lazyLoaderComponent"
    assert_includes renderer, 'source: active ? Qt.resolvedUrl("ControlNode.qml") : ""'
    assert_includes renderer, 'root.subscribed("loaded")'
  end

  def test_flickable_has_a_specific_native_kinetic_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "flickable"'
    assert_includes renderer, "id: flickableComponent"
    assert_includes renderer, "Flickable.HorizontalAndVerticalFlick"
    assert_includes renderer, '"flick_end", positionPayload()'
  end

  def test_focus_scope_has_a_specific_native_focus_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "focus_scope"'
    assert_includes renderer, "id: focusScopeComponent"
    assert_includes renderer, "FocusScope {"
    assert_includes renderer, "forceActiveFocus()"
  end

  def test_flipable_has_a_specific_native_two_face_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "flipable"'
    assert_includes renderer, "id: flipableComponent"
    assert_includes renderer, "Flipable {"
    assert_includes renderer, "Behavior on angle"
    assert_includes renderer, "root.configureFace(item, root.node.children[1])"
  end

  def test_border_image_has_a_specific_native_nine_slice_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "border_image"'
    assert_includes renderer, "id: borderImageComponent"
    assert_includes renderer, "BorderImage {"
    assert_includes renderer, 'border.left: Number(root.prop("border_left", 0))'
    assert_includes renderer, "BorderImage.Round"
  end

  def test_label_has_a_specific_native_styled_text_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "label"'
    assert_includes renderer, "id: labelComponent"
    assert_includes renderer, "QQC.Label {"
    assert_includes renderer, "Text.MarkdownText"
    assert_includes renderer, '"link", { value: link }'
  end

  def test_rich_text_has_an_explicit_native_markup_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "rich_text"'
    assert_includes renderer, "id: richTextComponent"
    assert_includes renderer, "textFormat: Text.RichText"
    assert_includes renderer, "linkColor: root.prop"
  end

  def test_markdown_has_a_specific_native_document_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "markdown"'
    assert_includes renderer, "id: markdownComponent"
    assert_includes renderer, "textFormat: Text.MarkdownText"
    assert_includes renderer, 'baseUrl: String(root.prop("base_url", ""))'
  end

  def test_selectable_text_has_a_specific_native_selection_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "selectable_text"'
    assert_includes renderer, "id: selectableTextComponent"
    assert_includes renderer, "selectByMouse: true"
    assert_includes renderer, '"selection", {'
  end

  def test_animated_image_has_a_specific_native_playback_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "animated_image"'
    assert_includes renderer, "id: animatedImageComponent"
    assert_includes renderer, "AnimatedImage {"
    assert_includes renderer, 'root.prop("speed", 1)'
    assert_includes renderer, '"frame", { value: currentFrame, count: frameCount }'
  end

  def test_vector_image_has_a_specific_native_svg_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, "import QtQuick.VectorImage"
    assert_includes renderer, 'node.type === "vector_image"'
    assert_includes renderer, "id: vectorImageComponent"
    assert_includes renderer, "VectorImage.CurveRenderer"
    vector_image = source("Components/Builtins/VectorImage.qml")
    assert_includes vector_image, 'source: renderer.assetUrl(renderer.prop("source", ""))'
    assert_includes vector_image, 'vectorRoot["animations"]'
    assert_includes vector_image, 'vectorRoot["assumeTrustedSource"]'
    assert_includes vector_image, 'vectorRoot["asynchronousShapes"]'
    assert_includes vector_image, "controller.paused = paused"
    assert_includes vector_image, 'componentError("vector_animation_unsupported"'
    assert_includes vector_image, 'componentError("trusted_vector_unsupported"'
    assert_includes vector_image, 'componentError("asynchronous_vector_unsupported"'
  end

  def test_model_view_3d_loads_real_geometry_and_native_pointer_controls
    renderer = File.read(File.join(ROOT, "ControlNode.qml"))
    host = source("Components/Builtins/ModelView3d.qml")
    model = source("Components/Builtins/Support/ModelView3dScene.qml")

    assert_includes renderer, '"model_view_3d"'
    assert_includes renderer, "builtInSource(node.type)"
    refute_includes renderer, "id: modelView3dComponent"
    assert_includes host, 'Qt.resolvedUrl("Support/ModelView3dScene.qml")'
    refute_includes host, "Image {"
    refute_match(/fallback_(?:source|text|fill_mode|while_loading)|prefer_3d/, host)
    assert_includes host, 'renderer.componentError("qtquick3d_unavailable"'
    assert_includes model, "import QtQuick3D"
    assert_includes model, "import QtQuick3D.AssetUtils"
    assert_includes model, "View3D {"
    assert_includes model, "RuntimeLoader {"
    assert_includes model, "function synchronizeModelSource()"
    assert_includes model, "requestedSource === loadedModelSource"
    assert_includes model, 'source: ""'
    assert_includes model, "onBoundsChanged: modelViewRoot.updateBounds()"
    assert_includes model, "DragHandler {"
    assert_includes model, "PinchHandler {"
    assert_includes model, "WheelHandler {"
    assert_includes model, "onDoubleTapped:"
    refute_match(/\b(?:bpm|beatAmount|pulse_scale)\b/, model)
    refute_includes Zui::COMPONENTS.fetch(:model_view_3d).first, :bpm
    refute_includes Zui::COMPONENTS.fetch(:model_view_3d).first, :pulse
    refute_includes Zui::COMPONENTS.fetch(:model_view_3d).first, :pulse_scale
    assert_includes model, "temporalAAEnabled: false"
  end

  def test_font_loader_has_a_specific_native_resource_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "font_loader"'
    assert_includes renderer, "id: fontLoaderComponent"
    assert_includes renderer, "FontLoader {"
    assert_includes renderer, '"loaded", { name: name }'
  end

  def test_text_metrics_has_a_specific_native_measurement_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "text_metrics"'
    assert_includes renderer, "id: textMetricsComponent"
    assert_includes renderer, "TextMetrics {"
    assert_includes renderer, "advance_width: advanceWidth"
    assert_includes renderer, "tight_bounding_rect:"
  end

  def test_video_has_a_specific_native_multimedia_renderer
    video = source("Components/Builtins/Video.qml")
    video_output = source("Components/Builtins/VideoOutput.qml")

    assert_includes video, "import QtMultimedia"
    assert_includes video, "VideoOutput.PreserveAspectCrop"
    assert_includes video, '"position", { value: position, duration: duration }'
    assert_includes video, 'videoRoot["mirrored"]'
    assert_includes video, 'componentError("video_mirroring_unsupported"'
    assert_includes video_output, 'videoRoot["endOfStreamPolicy"]'
    assert_includes video_output, 'componentError("video_end_policy_unsupported"'
  end

  def test_audio_has_a_specific_native_media_player_renderer
    audio = source("Components/Builtins/Audio.qml")

    assert_includes audio, "import QtMultimedia"
    assert_includes audio, "MediaPlayer {"
    assert_includes audio, "audioOutput: AudioOutput {"
    assert_includes audio, 'requested === "pause"'
    assert_includes audio, 'source: renderer.assetUrl(renderer.prop("source", ""))'
    assert_includes audio, "audioPlayer.setPosition"
    assert_includes audio, 'audioRoot.send("end"'
  end

  def test_reorderable_list_has_padded_fluid_drag_feedback
    list = source("Components/Builtins/ReorderableList.qml")

    assert_includes list, 'renderer.prop("item_padding", 12)'
    assert_includes list, 'renderer.prop("drag_transition_duration", 180)'
    assert_includes list, "Behavior on dragOffsetY"
    assert_includes list, "Easing.OutCubic"
    assert_includes list, 'target: null'
    assert_includes list, '"drag_move"'
  end

  def test_avatar_has_a_specific_image_and_initials_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "avatar"'
    assert_includes renderer, "id: avatarComponent"
    assert_includes renderer, "id: avatarImage"
    assert_includes renderer, "Image.PreserveAspectCrop"
    assert_includes renderer, ").toUpperCase()"
    assert_includes renderer, 'visible: avatarRoot.avatarSource === ""'
    assert_includes renderer, 'root.componentError("avatar_image_failed"'
  end

  def test_badge_has_a_specific_value_and_dot_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "badge"'
    assert_includes renderer, "id: badgeComponent"
    assert_includes renderer, 'String(maximum) + "+"'
    assert_includes renderer, 'root.prop("dot", false)'
  end

  def test_chip_has_a_specific_selectable_and_deletable_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "chip"'
    assert_includes renderer, "id: chipComponent"
    assert_includes renderer, 'root.prop("deletable", false)'
    assert_includes renderer, '"delete", {}'
    assert_includes renderer, '"change", { value: !chipRoot.selected }'
  end

  def test_divider_has_a_specific_oriented_line_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "divider"'
    assert_includes renderer, "id: dividerComponent"
    assert_includes renderer, 'root.prop("end_indent", 0)'
    assert_includes renderer, "parent.vertical ? parent.lineThickness"
  end

  def test_service_validates_structural_child_patches
    service = source("Service.qml")
    assert_includes service, 'message.op === "replace_children"'
    assert_includes service, 'return reject("invalid children patch")'
    assert_includes service, "validateNode(message.children[childIndex]"
  end

  def test_service_and_renderer_support_composed_animation_tracks
    service = source("Service.qml")
    renderer = source("ControlNode.qml")
    assert_includes service, 'message.op === "animate"'
    assert_includes service, "message.tracks.length > 64"
    assert_includes renderer, "propertyAnimationFactory.createObject"
    assert_includes renderer, "delayedAnimationFactory.createObject"
  end

  def test_reactive_patch_preserves_event_subscriptions
    service = File.read(File.join(ROOT, "Service.qml"))

    assert_includes service, "if (node.events !== undefined) replacement.events = node.events"
  end

  def test_rows_and_columns_apply_cross_axis_alignment
    renderer = source("ControlNode.qml")

    assert_includes renderer, "delegate: rowChildDelegate"
    assert_includes renderer, 'root.prop("alignment", "center")'
    assert_includes renderer, "anchors.verticalCenter"
    assert_includes renderer, "delegate: columnChildDelegate"
    assert_includes renderer, "anchors.horizontalCenter"
  end

  def test_responsive_layouts_and_named_icons_are_native_built_ins
    renderer = source("ControlNode.qml")

    assert_includes renderer, "import QtQuick.Layouts"
    assert_includes renderer, 'node.type === "row_layout"'
    assert_includes renderer, 'node.type === "column_layout"'
    assert_includes renderer, 'node.type === "grid_layout"'
    assert_includes renderer, 'node.type === "flow"'
    assert_includes renderer, 'node.type === "card"'
    assert_includes renderer, "Layout.fillWidth"
    assert_includes renderer, 'root.structuralContainer && root.subscribed("click")'
    assert_includes renderer, 'phone: "\\uf3cd"'
    assert_includes renderer, 'android: "\\uf17b"'
    assert_includes renderer, 'color: root.prop("color", root.foreground)'
  end

  def test_tooltip_uses_the_native_zui_panel_tooltip
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tooltip"'
    assert_includes renderer, "ZuiControls.PanelToolTip"
    assert_includes renderer, 'panelBackground: root.prop("background", Color.tooltip.background)'
  end

  def test_bar_icon_button_uses_native_optical_bar_control
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "bar_icon_button"'
    assert_includes renderer, "ZuiControls.BarIconButton"
    assert_includes renderer, 'slotSize: Number(root.prop("slot_size", Style.bar.iconSlot))'
    assert_includes renderer, '"middle_click"'
    assert_includes renderer, "onWheelMoved: function(delta)"
    assert_includes renderer, "onPressed: function(button)"
    refute_match(/ZuiControls\.(?:BarIconButton|BarIndicator)\s*\{[^}]*on(?:Wheel|Clicked|RightClicked|MiddleClicked):/m, renderer)
  end

  def test_bar_indicator_uses_native_active_inactive_control
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "bar_indicator"'
    assert_includes renderer, "ZuiControls.BarIndicator"
    assert_includes renderer, 'activeText: root.iconGlyph(root.prop("active_icon", ""))'
    assert_includes renderer, 'indicatorBlock: String(root.prop("indicator_block", "single"))'
  end

  def test_border_overlay_uses_native_gradient_border_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "border_overlay"'
    assert_includes renderer, "ZuiControls.BorderOverlay"
    assert_includes renderer, 'gradient: { colors: colors, angle: Number(root.prop("gradient_angle", 0)), enabled: true }'
  end

  def test_key_catcher_maps_all_native_keyboard_signals
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "key_catcher"'
    assert_includes renderer, "ZuiControls.PanelKeyCatcher"
    assert_includes renderer, '"move", { dx: dx, dy: dy }'
    assert_includes renderer, '"tab", { direction: direction }'
    assert_includes renderer, '"text", { text: text }'
  end

  def test_checkbox_has_omarchy_styling_and_value_event
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "checkbox"'
    assert_includes renderer, "QQC.CheckBox"
    assert_includes renderer, 'root.iconGlyph("check")'
    assert_includes renderer, '"change", { value: checked }'
  end

  def test_radio_button_has_a_specific_native_selection_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "radio_button"'
    assert_includes renderer, "id: radioButtonComponent"
    assert_includes renderer, "QQC.RadioButton {"
    assert_includes renderer, 'option: root.prop("value", null)'
  end

  def test_radio_group_has_a_specific_native_exclusive_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "radio_group"'
    assert_includes renderer, "id: radioGroupComponent"
    assert_includes renderer, "QQC.ButtonGroup { id: exclusiveRadioGroup }"
    assert_includes renderer, "QQC.ButtonGroup.group: exclusiveRadioGroup"
    assert_includes renderer, '"change", { value: optionValue, index: index }'
  end

  def test_line_chart_has_a_specific_canvas_renderer_and_events
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "line_chart"'
    assert_includes renderer, "id: lineChartComponent"
    assert_includes renderer, 'root.prop("fill_color", "")'
    assert_includes renderer, '"select", payload(mouse)'
    assert_includes renderer, '"hover", payload(mouse)'
  end

  def test_bar_chart_has_a_specific_canvas_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "bar_chart"'
    assert_includes renderer, "id: barChartComponent"
    assert_includes renderer, 'ctx.fillRect(left, top, Math.max(1, slot - gap), barHeight)'
  end

  def test_area_chart_has_a_specific_canvas_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "area_chart"'
    assert_includes renderer, "id: areaChartComponent"
    assert_includes renderer, 'ctx.fillStyle = root.prop("fill_color", root.prop("color", Color.accent))'
  end

  def test_bridge_bounds_values_and_renders_external_text_as_plain_text
    service = source("Service.qml")
    renderer = source("ControlNode.qml")

    assert_includes service, "function boundedValue(value, depth)"
    assert_includes service, "maxStringLength: 16384"
    assert_operator renderer.scan("textFormat: Text.PlainText").length, :>=, 2
    assert_includes renderer, "function escapeAutoText(value)"
    assert_includes renderer, 'tooltipText: root.escapeAutoText(root.prop("tooltip", ""))'
  end

  def test_text_area_has_a_specific_native_multiline_renderer
    renderer = source("ControlNode.qml")
    text_area = source("Components/Builtins/TextArea.qml")

    assert_includes renderer, 'node.type === "text_area"'
    assert_includes renderer, "id: textAreaComponent"
    assert_includes renderer, "QQC.TextArea {"
    assert_includes renderer, '"selection", { start: selectionStart'
    assert_includes text_area, 'nativeTextArea["textEdited"]'
    assert_includes text_area, "ignoreUnknownSignals: true"
    assert_includes text_area, "if (!supportsTextEditedSignal && activeFocus) sendInputEvent()"
    refute_includes text_area, "onTextEdited:"
  end

  def test_search_field_has_a_specific_native_suggestion_renderer
    renderer = source("ControlNode.qml")
    search_field = source("Components/Builtins/SearchField.qml")

    assert_includes renderer, 'node.type === "search_field"'
    assert_includes renderer, "id: searchFieldComponent"
    assert_includes search_field, "QQC.TextField {"
    assert_includes search_field, 'suggestionModel: renderer.prop("suggestions", [])'
    assert_includes search_field, "id: suggestionPopup"
    assert_includes search_field, "Keys.onDownPressed"
    assert_includes search_field, "activateSuggestion(highlightedIndex)"
    assert_includes renderer, '"search", { value: text }'
    refute_includes search_field, "QQC.SearchField"
  end

  def test_password_field_has_a_specific_masked_reveal_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "password_field"'
    assert_includes renderer, "id: passwordFieldComponent"
    assert_includes renderer, "password: !passwordRoot.revealState"
    assert_includes renderer, '"reveal", { value: passwordRoot.revealState }'
  end

  def test_range_slider_has_a_specific_native_two_handle_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "range_slider"'
    assert_includes renderer, "id: rangeSliderComponent"
    assert_includes renderer, "QQC.RangeSlider {"
    assert_includes renderer, "first.onMoved:"
    assert_includes renderer, "return { lower: first.value, upper: second.value }"
  end

  def test_dial_has_a_specific_native_angular_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "dial"'
    assert_includes renderer, "id: dialComponent"
    assert_includes renderer, "QQC.Dial {"
    assert_includes renderer, "QQC.Dial.Circular"
    assert_includes renderer, '"input", { value: value, angle: angle }'
  end

  def test_spin_box_has_a_specific_native_integer_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "spin_box"'
    assert_includes renderer, "id: spinBoxComponent"
    assert_includes renderer, "QQC.SpinBox {"
    assert_includes renderer, "textFromValue: function(value, locale)"
    assert_includes renderer, '"increase", { value: value }'
  end

  def test_double_spin_box_has_a_specific_native_floating_renderer
    renderer = source("ControlNode.qml")
    double_spin_box = source("Components/Builtins/DoubleSpinBox.qml")

    assert_includes renderer, 'node.type === "double_spin_box"'
    assert_includes renderer, "id: doubleSpinBoxComponent"
    assert_includes double_spin_box, "QQC.SpinBox {"
    assert_includes double_spin_box, "readonly property real scaleFactor"
    assert_includes double_spin_box, "readonly property real realValue"
    assert_includes renderer, 'root.prop("decimals", 2)'
    assert_includes double_spin_box, 'toLocaleString(locale, "f", decimalPlaces)'
    refute_includes double_spin_box, "QQC.DoubleSpinBox"
  end

  def test_color_picker_has_a_specific_native_dialog_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "color_picker"'
    assert_includes renderer, "id: colorPickerComponent"
    assert_includes renderer, "ColorDialog {"
    assert_includes renderer, 'selectedColor: root.prop("color", "#ffffff")'
    assert_includes renderer, "ColorDialog.ShowAlphaChannel"
    assert_includes renderer, '"input", {'
    assert_includes renderer, '"change", { value: value }'
    assert_includes renderer, '"accept", { value: value }'
    assert_includes renderer, '"reject", {'
  end

  def test_date_picker_has_a_specific_native_calendar_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "date_picker"'
    assert_includes renderer, "id: datePickerComponent"
    assert_includes renderer, "Basic.MonthGrid {"
    assert_includes renderer, 'root.prop("minimum", "")'
    assert_includes renderer, 'root.prop("maximum", "")'
    assert_includes renderer, '"input", { value: value }'
    assert_includes renderer, '"change", { value: value }'
    assert_includes renderer, '"navigate", {'
  end

  def test_time_picker_has_a_specific_native_spin_control_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "time_picker"'
    assert_includes renderer, "id: timePickerComponent"
    assert_includes renderer, "QQC.SpinBox {"
    assert_includes renderer, 'root.prop("use_24_hour", true)'
    assert_includes renderer, 'root.prop("show_seconds", false)'
    assert_includes renderer, '"input", { value: value }'
    assert_includes renderer, '"change", { value: value }'
    assert_includes renderer, '"accept", { value: value }'
    assert_includes renderer, '"reject", {'
    assert_includes renderer, "value: picker.formattedTime()"
  end

  def test_file_picker_has_specific_native_file_and_folder_dialog_renderers
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "file_picker"'
    assert_includes renderer, "id: filePickerComponent"
    assert_includes renderer, "FileDialog {"
    assert_includes renderer, "FolderDialog {"
    assert_includes renderer, "FileDialog.OpenFiles"
    assert_includes renderer, "FileDialog.SaveFile"
    assert_includes renderer, 'root.prop("filters", [])'
    assert_includes renderer, '"change", payload'
    assert_includes renderer, '"folder_change", { value: value }'
  end

  def test_folder_picker_has_a_specific_native_directory_dialog_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "folder_picker"'
    assert_includes renderer, "id: folderPickerComponent"
    assert_includes renderer, "FolderDialog {"
    assert_includes renderer, 'root.prop("current_folder", root.prop("path", ""))'
    assert_includes renderer, "FolderDialog.DontUseNativeDialog"
    assert_includes renderer, '"input", payload'
    assert_includes renderer, '"change", payload'
    assert_includes renderer, '"folder_change", { value: value }'
  end

  def test_font_picker_has_a_specific_native_font_dialog_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "font_picker"'
    assert_includes renderer, "id: fontPickerComponent"
    assert_includes renderer, "FontDialog {"
    assert_includes renderer, "Qt.font(specification)"
    assert_includes renderer, "family: value.family"
    assert_includes renderer, 'root.prop("point_size", -1)'
    assert_includes renderer, '"input", picker.fontPayload(selectedFont)'
    assert_includes renderer, '"change", payload'
    assert_includes renderer, '"accept", payload'
  end

  def test_dialog_button_box_has_a_specific_native_role_aware_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "dialog_button_box"'
    assert_includes renderer, "id: dialogButtonBoxComponent"
    assert_includes renderer, "QQC.DialogButtonBox {"
    assert_includes renderer, "standardButtons: standardButtonsValue"
    assert_includes renderer, "QQC.DialogButtonBox.buttonRole: box.roleValue"
    assert_includes renderer, "ListView.Vertical : ListView.Horizontal"
    assert_includes renderer, 'root.prop("custom_buttons", [])'
    assert_includes renderer, '"click", box.buttonPayload(button)'
    assert_includes renderer, '"accept", {}'
    assert_includes renderer, '"reject", {}'
    assert_includes renderer, '"help", {}'
  end

  def test_action_has_a_specific_native_nonvisual_command_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "action"'
    assert_includes renderer, "id: actionComponent"
    assert_includes renderer, "QQC.Action {"
    assert_includes renderer, "property alias nativeAction: nativeAction"
    assert_includes renderer, 'shortcut: root.prop("shortcut", "")'
    assert_includes renderer, 'icon.name: String(root.prop("icon", ""))'
    assert_includes renderer, '"trigger", actionRoot.payload()'
    assert_includes renderer, '"toggle", actionRoot.payload()'
    assert_includes renderer, '"change", actionRoot.payload()'
  end

  def test_action_group_resolves_ruby_action_nodes_into_a_native_group
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "action_group"'
    assert_includes renderer, "id: actionGroupComponent"
    assert_includes renderer, "QQC.ActionGroup {"
    assert_includes renderer, 'root.prop("action_ids", [])'
    assert_includes renderer, "root.findRenderedItem(actionId)"
    assert_includes renderer, "nativeGroup.addAction(rendered.nativeAction)"
    assert_includes renderer, "nativeGroup.removeAction(attached[index].action)"
    assert_includes renderer, '"trigger", groupRoot.actionPayload(action)'
    assert_includes renderer, '"change", groupRoot.actionPayload(checkedAction)'
    assert_includes renderer, '"actions_change", {'
    assert_includes renderer, "values: attachedIds()"
  end

  def test_page_has_a_specific_native_navigation_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "page"'
    assert_includes renderer, "id: pageComponent"
    assert_includes renderer, "QQC.Page {"
    assert_includes renderer, 'title: String(root.prop("title", ""))'
    assert_includes renderer, 'root.prop("header_text", pageRoot.title)'
    assert_includes renderer, 'root.prop("footer_text", "")'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, 'visible ? "show" : "hide"'
    assert_includes renderer, 'activeFocus ? "focus" : "blur"'
    assert_includes renderer, '"title_change", { value: title }'
  end

  def test_pane_has_a_specific_native_content_surface_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "pane"'
    assert_includes renderer, "id: paneComponent"
    assert_includes renderer, "QQC.Pane {"
    assert_includes renderer, 'root.prop("left_padding", padding)'
    assert_includes renderer, 'root.prop("right_padding", padding)'
    assert_includes renderer, 'root.prop("top_padding", padding)'
    assert_includes renderer, 'root.prop("bottom_padding", padding)'
    assert_includes renderer, 'root.prop("layout_direction", "left_to_right")'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, 'visible ? "show" : "hide"'
    assert_includes renderer, 'activeFocus ? "focus" : "blur"'
  end

  def test_frame_has_a_specific_native_bordered_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "frame"'
    assert_includes renderer, "id: frameComponent"
    assert_includes renderer, "QQC.Frame {"
    assert_includes renderer, 'root.prop("border_width", Style.normalBorderWidth)'
    assert_includes renderer, 'root.prop("border_color", Color.border)'
    assert_includes renderer, 'root.prop("left_padding", padding)'
    assert_includes renderer, 'root.prop("layout_direction", "left_to_right")'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, 'visible ? "show" : "hide"'
    assert_includes renderer, 'activeFocus ? "focus" : "blur"'
  end

  def test_group_box_has_a_specific_native_titled_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "group_box"'
    assert_includes renderer, "id: groupBoxComponent"
    assert_includes renderer, "QQC.GroupBox {"
    assert_includes renderer, 'title: String(root.prop("title", ""))'
    assert_includes renderer, 'root.prop("title_alignment", "left")'
    assert_includes renderer, 'root.prop("top_padding", padding + titleLabel.implicitHeight + Style.spacing.sm)'
    assert_includes renderer, 'root.prop("border_color", Color.border)'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, '"title_change", { value: title }'
  end

  def test_tabs_has_a_specific_native_bar_and_stack_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tabs"'
    assert_includes renderer, "id: tabsComponent"
    assert_includes renderer, "QQC.TabBar {"
    assert_includes renderer, "QQC.TabButton {"
    assert_includes renderer, "StackLayout {"
    assert_includes renderer, 'root.prop("labels", [])'
    assert_includes renderer, 'root.prop("current_index", 0)'
    assert_includes renderer, 'root.prop("position", "top")'
    assert_includes renderer, "delegate: layoutChildDelegate"
    assert_includes renderer, '"tab_click", { value: index, label: text }'
    assert_includes renderer, '"input", { value: currentIndex }'
    assert_includes renderer, '"change", { value: currentIndex }'
  end

  def test_tab_bar_has_a_specific_native_selection_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tab_bar"'
    assert_includes renderer, "id: tabBarComponent"
    assert_includes renderer, "QQC.TabBar {"
    assert_includes renderer, "QQC.TabButton {"
    assert_includes renderer, 'root.prop("items", [])'
    assert_includes renderer, 'root.prop("current_index", 0)'
    assert_includes renderer, 'root.prop("position", "top")'
    assert_includes renderer, 'itemValue(index, "enabled", true)'
    assert_includes renderer, 'itemValue(index, "icon", "")'
    assert_includes renderer, '"tab_click", { value: index, label: text }'
    assert_includes renderer, '"input", { value: currentIndex }'
    assert_includes renderer, '"change", { value: currentIndex }'
  end

  def test_tab_button_has_a_specific_native_button_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tab_button"'
    assert_includes renderer, "id: tabButtonComponent"
    assert_includes renderer, "QQC.TabButton {"
    assert_includes renderer, 'checked: root.prop("checked", false) === true'
    assert_includes renderer, 'autoExclusive: root.prop("auto_exclusive", true) !== false'
    assert_includes renderer, "Shortcut {"
    assert_includes renderer, 'sequence: String(root.prop("shortcut", ""))'
    assert_includes renderer, 'root.iconGlyph(root.prop("icon", ""))'
    assert_includes renderer, '"click",'
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
    assert_includes renderer, '"hover", { value: hovered }'
  end

  def test_page_indicator_has_a_specific_native_paging_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "page_indicator"'
    assert_includes renderer, "id: pageIndicatorComponent"
    assert_includes renderer, "QQC.PageIndicator {"
    assert_includes renderer, 'count: Math.max(0, Number(root.prop("count", 0)))'
    assert_includes renderer, 'root.prop("current_index", 0)'
    assert_includes renderer, 'interactive: root.prop("interactive", false) === true'
    assert_includes renderer, 'root.prop("dot_size", 8)'
    assert_includes renderer, 'index === indicatorRoot.currentIndex'
    assert_includes renderer, '"input", { value: currentIndex }'
    assert_includes renderer, '"change", { value: currentIndex }'
  end

  def test_stack_view_has_a_specific_native_push_pop_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "stack_view"'
    assert_includes renderer, "id: stackViewComponent"
    assert_includes renderer, "QQC.StackView {"
    assert_includes renderer, 'root.prop("current_index", 0)'
    assert_includes renderer, "childDelegate.createObject"
    assert_includes renderer, "push(page, {}, operationFor(target))"
    assert_includes renderer, "pop(operationFor(target)"
    assert_includes renderer, "clear(QQC.StackView.Immediate)"
    assert_includes renderer, '"push",'
    assert_includes renderer, '"pop",'
    assert_includes renderer, '"depth_change",'
    assert_includes renderer, '"busy_change", { value: busy }'
    assert_includes renderer, '"change",'
  end

  def test_swipe_view_has_a_specific_native_gesture_paging_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "swipe_view"'
    assert_includes renderer, "id: swipeViewComponent"
    assert_includes renderer, "QQC.SwipeView {"
    assert_includes renderer, 'root.prop("current_index", 0)'
    assert_includes renderer, 'interactive: root.prop("interactive", true) !== false'
    assert_includes renderer, 'root.prop("orientation", "horizontal")'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, '"input", { value: currentIndex }'
    assert_includes renderer, '"change", { value: currentIndex }'
    assert_includes renderer, '"count_change", { value: count }'
  end

  def test_drawer_has_a_specific_native_edge_popup_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "drawer"'
    assert_includes renderer, "id: drawerComponent"
    assert_includes renderer, "QQC.Drawer {"
    assert_includes renderer, 'root.prop("opened", false) === true'
    assert_includes renderer, 'edgeValue(root.prop("edge", "left"))'
    assert_includes renderer, 'modal: root.prop("modal", true) !== false'
    assert_includes renderer, 'interactive: root.prop("interactive", true) !== false'
    assert_includes renderer, 'closePolicyValue(root.prop("close_policy", "escape_and_outside"))'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, '"open",'
    assert_includes renderer, '"close",'
    assert_includes renderer, '"about_to_show", {}'
    assert_includes renderer, '"about_to_hide", {}'
    assert_includes renderer, '"position_change", { value: position }'
  end

  def test_navigation_rail_has_a_specific_native_destination_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "navigation_rail"'
    assert_includes renderer, "id: navigationRailComponent"
    assert_includes renderer, "QQC.Pane {"
    assert_includes renderer, "QQC.ToolButton {"
    assert_includes renderer, 'root.prop("items", [])'
    assert_includes renderer, 'root.prop("current_index", 0)'
    assert_includes renderer, 'root.prop("extended", false) === true'
    assert_includes renderer, 'itemValue(index, "enabled", true)'
    assert_includes renderer, 'itemValue(index, "icon_source", "")'
    assert_includes renderer, '"select",'
    assert_includes renderer, '"input", { value: currentIndex }'
    assert_includes renderer, '"change", { value: currentIndex }'
  end

  def test_breadcrumb_has_a_specific_native_trail_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "breadcrumb"'
    assert_includes renderer, "id: breadcrumbComponent"
    assert_includes renderer, "QQC.Pane {"
    assert_includes renderer, "QQC.ToolButton {"
    assert_includes renderer, 'root.prop("items", [])'
    assert_includes renderer, 'root.prop("current_index",'
    assert_includes renderer, 'itemValue(index, "value", itemLabel(index))'
    assert_includes renderer, 'itemValue(index, "enabled", true)'
    assert_includes renderer, 'root.prop("separator", "chevron_right")'
    assert_includes renderer, '"select", breadcrumbRoot.itemPayload(index)'
    assert_includes renderer, '"input", payload'
    assert_includes renderer, '"change", payload'
  end

  def test_pagination_has_a_specific_native_bounded_page_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "pagination"'
    assert_includes renderer, "id: paginationComponent"
    assert_includes renderer, "QQC.Pane {"
    assert_includes renderer, "QQC.ToolButton {"
    assert_includes renderer, 'root.prop("count", 0)'
    assert_includes renderer, 'root.prop("page", 1)'
    assert_includes renderer, 'root.prop("sibling_count", 1)'
    assert_includes renderer, "result.push(0)"
    assert_includes renderer, 'root.prop("show_previous_next", true)'
    assert_includes renderer, 'root.prop("show_first_last", false)'
    assert_includes renderer, '"previous"'
    assert_includes renderer, '"next"'
    assert_includes renderer, '"select", payload'
    assert_includes renderer, '"change", payload'
  end

  def test_expansion_panel_has_a_specific_native_reveal_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "expansion_panel"'
    assert_includes renderer, "id: expansionPanelComponent"
    assert_includes renderer, "QQC.Control {"
    assert_includes renderer, "QQC.ToolButton {"
    assert_includes renderer, 'root.prop("expanded", false) === true'
    assert_includes renderer, 'root.prop("title", "")'
    assert_includes renderer, 'root.prop("subtitle", "")'
    assert_includes renderer, "Behavior on height"
    assert_includes renderer, 'root.easingType(root.prop("easing", "in_out_quad"))'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
    assert_includes renderer, 'expanded ? "expand" : "collapse"'
  end

  def test_accordion_has_a_specific_native_multi_section_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "accordion"'
    assert_includes renderer, "id: accordionComponent"
    assert_includes renderer, "QQC.Control {"
    assert_includes renderer, "QQC.ToolButton {"
    assert_includes renderer, 'root.prop("titles", [])'
    assert_includes renderer, 'root.prop("expanded_indices", [])'
    assert_includes renderer, 'root.prop("multiple", false)'
    assert_includes renderer, 'source: Qt.resolvedUrl("ControlNode.qml")'
    assert_includes renderer, 'item.controlId = String(root.node.children[sectionRoot.index].id)'
    assert_includes renderer, "Behavior on height"
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
    assert_includes renderer, 'opening ? "expand" : "collapse"'
  end

  def test_tool_bar_has_a_specific_native_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tool_bar"'
    assert_includes renderer, "id: toolBarComponent"
    assert_includes renderer, "QQC.ToolBar {"
    assert_includes renderer, 'root.prop("position", "header")'
    assert_includes renderer, "QQC.ToolBar.Footer"
    assert_includes renderer, 'root.prop("layout", "row")'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, '"position_change",'
    assert_includes renderer, '"footer" : "header"'
    assert_includes renderer, '"click", {}'
  end

  def test_tool_separator_has_a_specific_native_separator_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tool_separator"'
    assert_includes renderer, "id: toolSeparatorComponent"
    assert_includes renderer, "QQC.ToolSeparator {"
    assert_includes renderer, 'root.prop("orientation", "vertical")'
    assert_includes renderer, 'orientation: String(root.prop("orientation", "vertical")) === "vertical"'
    assert_includes renderer, 'root.prop("thickness", 1)'
    assert_includes renderer, 'root.prop("length", 32)'
    assert_includes renderer, 'root.prop("padding", 8)'
    assert_includes renderer, 'root.prop("color", root.foreground)'
    assert_includes renderer, 'visible ? "show" : "hide"'
  end

  def test_menu_has_a_specific_native_popup_entry_renderer
    renderer = source("ControlNode.qml")
    menu = source("Components/Builtins/Menu.qml")

    assert_includes renderer, 'node.type === "menu"'
    assert_includes renderer, "id: menuComponent"
    assert_includes renderer, "QQC.Menu {"
    assert_includes renderer, "QQC.MenuItem {"
    assert_includes renderer, "QQC.MenuSeparator {"
    assert_includes renderer, 'root.prop("items", [])'
    assert_includes renderer, 'root.prop("opened", false) === true'
    assert_includes renderer, "Instantiator {"
    assert_includes renderer, "DelegateChooser {"
    assert_includes renderer, "menuRoot.insertItem(index, object)"
    assert_includes renderer, "menuRoot.removeItem(object)"
    assert_includes renderer, 'entryValue(modelData, "checkable", false)'
    assert_includes renderer, 'entryValue(modelData, "checked", false)'
    assert_includes renderer, '"trigger", menuRoot.entryPayload(index, modelData, this)'
    assert_includes renderer, '"toggle", menuRoot.entryPayload(index, modelData, this)'
    assert_includes renderer, '"highlight", menuRoot.entryPayload(index, modelData, this)'
    assert_includes renderer, '"about_to_show", {}'
    assert_includes renderer, '"about_to_hide", {}'
    assert_includes menu, "import Qt.labs.qmlmodels"
    refute_includes menu, "import QtQml.Models"
  end

  def test_menu_item_has_a_specific_native_entry_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "menu_item"'
    assert_includes renderer, "id: menuItemComponent"
    assert_includes renderer, "QQC.MenuItem {"
    assert_includes renderer, 'text: String(root.prop("text", ""))'
    assert_includes renderer, 'checkable: root.prop("checkable", false) === true'
    assert_includes renderer, 'checked: root.prop("checked", false) === true'
    assert_includes renderer, 'highlighted: root.prop("highlighted", false) === true'
    assert_includes renderer, "Shortcut {"
    assert_includes renderer, 'sequence: String(root.prop("shortcut", ""))'
    assert_includes renderer, '"trigger", payload(false)'
    assert_includes renderer, '"toggle", current'
    assert_includes renderer, '"change", current'
    assert_includes renderer, '"highlight", { value: highlighted }'
  end

  def test_menu_separator_has_a_specific_native_separator_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "menu_separator"'
    assert_includes renderer, "id: menuSeparatorComponent"
    assert_includes renderer, "QQC.MenuSeparator {"
    assert_includes renderer, 'root.prop("thickness", 1)'
    assert_includes renderer, 'root.prop("width", 220)'
    assert_includes renderer, 'root.prop("padding", 8)'
    assert_includes renderer, 'root.prop("opacity", 0.25)'
    assert_includes renderer, 'root.prop("color", root.foreground)'
    assert_includes renderer, 'visible ? "show" : "hide"'
  end

  def test_menu_bar_has_a_specific_native_hierarchical_renderer
    renderer = source("ControlNode.qml")
    menu_bar = source("Components/Builtins/MenuBar.qml")

    assert_includes renderer, 'node.type === "menu_bar"'
    assert_includes renderer, "id: menuBarComponent"
    assert_includes renderer, "QQC.MenuBar {"
    assert_includes renderer, "QQC.Menu {"
    assert_includes renderer, "QQC.MenuItem {"
    assert_includes renderer, "QQC.MenuSeparator {"
    assert_includes renderer, 'root.prop("menus", [])'
    assert_includes renderer, "menuBarRoot.insertMenu(index, object)"
    assert_includes renderer, "nativeMenu.insertItem(index, object)"
    assert_includes renderer, "menu_index: menuIndex"
    assert_includes renderer, "item_index: itemIndex"
    assert_includes renderer, '"trigger", menuBarRoot.itemPayload'
    assert_includes renderer, '"toggle", menuBarRoot.itemPayload'
    assert_includes renderer, '"menu_open",'
    assert_includes renderer, '"menu_close",'
    assert_includes menu_bar, "import Qt.labs.qmlmodels"
    refute_includes menu_bar, "import QtQml.Models"
  end

  def test_context_menu_has_a_specific_native_targeted_popup_renderer
    renderer = source("ControlNode.qml")
    context_menu = source("Components/Builtins/ContextMenu.qml")

    assert_includes renderer, 'node.type === "context_menu"'
    assert_includes renderer, "id: contextMenuComponent"
    assert_includes renderer, "QQC.Menu {"
    assert_includes renderer, "QQC.MenuItem {"
    assert_includes renderer, "QQC.MenuSeparator {"
    assert_includes renderer, 'root.findRenderedItem(targetId)'
    assert_includes renderer, "acceptedButtons: Qt.RightButton"
    assert_includes renderer, "host.mapToItem(contextRoot, eventPoint.position)"
    assert_includes renderer, "nativeMenu.popup(localPoint)"
    assert_includes renderer, 'root.prop("opened", false) === true'
    assert_includes renderer, '"request",'
    assert_includes renderer, '"trigger", contextRoot.entryPayload'
    assert_includes renderer, '"toggle", contextRoot.entryPayload'
    assert_includes renderer, '"open", {}'
    assert_includes renderer, '"close", {}'
    assert_includes context_menu, "import Qt.labs.qmlmodels"
    refute_includes context_menu, "import QtQml.Models"
  end

  def test_popup_has_a_specific_native_container_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "popup"'
    assert_includes renderer, "id: popupComponent"
    assert_includes renderer, "QQC.Popup {"
    assert_includes renderer, 'root.prop("opened", false) === true'
    assert_includes renderer, 'modal: root.prop("modal", false) === true'
    assert_includes renderer, 'dim: root.prop("dim", modal) !== false'
    assert_includes renderer, 'focus: root.prop("focus", true) !== false'
    assert_includes renderer, 'closePolicyValue(root.prop("close_policy", "escape_and_outside"))'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, "enter: Transition {"
    assert_includes renderer, "exit: Transition {"
    assert_includes renderer, 'root.easingType(root.prop("easing", "out_cubic"))'
    assert_includes renderer, '"open", {}'
    assert_includes renderer, '"close", {}'
    assert_includes renderer, '"position_change", { x: x, y: y }'
  end

  def test_dialog_has_a_specific_native_standard_button_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "dialog"'
    assert_includes renderer, "id: dialogComponent"
    assert_includes renderer, "QQC.Dialog {"
    assert_includes renderer, 'title: String(root.prop("title", ""))'
    assert_includes renderer, 'standardButtonsValue(root.prop("standard_buttons", ["ok", "cancel"]))'
    assert_includes renderer, "QQC.Dialog.SaveAll"
    assert_includes renderer, "QQC.Dialog.RestoreDefaults"
    assert_includes renderer, 'modal: root.prop("modal", true) !== false'
    assert_includes renderer, "parent: QQC.Overlay.overlay"
    assert_includes renderer, 'root.prop("centered", true)'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, '"accept", {}'
    assert_includes renderer, '"reject", {}'
    assert_includes renderer, '"apply", {}'
    assert_includes renderer, '"reset", {}'
    assert_includes renderer, '"discard", {}'
    assert_includes renderer, '"help", {}'
  end

  def test_alert_dialog_has_a_specific_native_severity_renderer
    renderer = source("ControlNode.qml")
    alert = source("Components/Builtins/AlertDialog.qml")

    assert_includes renderer, 'node.type === "alert_dialog"'
    assert_includes renderer, "id: alertDialogComponent"
    assert_includes alert, "QQC.Dialog {"
    assert_includes alert, 'renderer.prop("severity", "info")'
    assert_includes alert, 'renderer.prop("show_icon", true)'
    assert_includes alert, "anchors.verticalCenter: parent.verticalCenter"
    assert_includes alert, 'renderer.prop("message", "")'
    assert_includes alert, 'renderer.prop("informative_text", "")'
    assert_includes alert, 'renderer.prop("detailed_text", "")'
    assert_includes alert, "QQC.ScrollView {"
    assert_includes alert, "QQC.TextArea {"
    assert_includes alert, "standardButtons: QQC.Dialog.NoButton"
    assert_includes alert, "parent: QQC.Overlay.overlay"
    assert_includes alert, 'renderer.prop("centered", true)'
    assert_includes alert, "Math.round((parent.width - width) / 2)"
    assert_includes alert, "Math.round((parent.height - height) / 2)"
    assert_includes alert, "delegate: ZuiControls.Button {"
    assert_includes alert, 'renderer.prop("button_accent"'
    assert_includes alert, 'renderer.prop("image"'
    assert_includes alert, "renderer.assetUrl(alertRoot.imageSource)"
    assert_includes alert, '"accept", {'
    assert_includes alert, '"reject", {'
  end

  def test_image_resolves_app_assets_and_exposes_native_loading_controls
    image = source("Components/Builtins/Image.qml")

    assert_includes image, 'source: renderer.assetUrl(renderer.prop("source", ""))'
    assert_includes image, 'renderer.prop("fill_mode", "preserve_aspect_fit")'
    assert_includes image, 'renderer.prop("asynchronous", true)'
    assert_includes image, 'renderer.prop("cache", true)'
    assert_includes image, 'renderer.prop("horizontal_alignment", "center")'
    assert_includes image, 'renderer.prop("vertical_alignment", "center")'
    assert_includes image, 'send("loaded", payload)'
    assert_includes image, 'renderer.componentError("image_load_failed"'
  end

  def test_message_dialog_has_a_specific_platform_native_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "message_dialog"'
    assert_includes renderer, "id: messageDialogComponent"
    assert_includes renderer, "Dialogs.MessageDialog {"
    assert_includes renderer, 'root.prop("message", "")'
    assert_includes renderer, 'root.prop("informative_text", "")'
    assert_includes renderer, 'root.prop("detailed_text", "")'
    assert_includes renderer, 'buttonsValue(root.prop("buttons", ["ok"]))'
    assert_includes renderer, 'modalityValue(root.prop("modality", "application"))'
    assert_includes renderer, '"button", {'
    assert_includes renderer, "button: buttonName(button), role: roleName(role)"
    assert_includes renderer, '"accept", {}'
    assert_includes renderer, '"reject", {}'
    assert_includes renderer, 'visible ? "open" : "close"'
  end

  def test_bottom_sheet_has_a_specific_draggable_popup_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "bottom_sheet"'
    assert_includes renderer, "id: bottomSheetComponent"
    assert_includes renderer, "id: sheetRoot"
    assert_includes renderer, "QQC.Popup {"
    assert_includes renderer, 'parent.height - height - sheetMargin'
    assert_includes renderer, 'root.prop("max_width", 720)'
    assert_includes renderer, "DragHandler {"
    assert_includes renderer, 'root.prop("dismiss_threshold", 0.3)'
    assert_includes renderer, '"drag", {'
    assert_includes renderer, '"drag_end", {'
    assert_includes renderer, '"dismiss", {'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, 'property: "y"'
  end

  def test_modal_sheet_has_a_specific_edge_attached_popup_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "modal_sheet"'
    assert_includes renderer, "id: modalSheetComponent"
    assert_includes renderer, "id: modalSheetRoot"
    assert_includes renderer, 'root.prop("edge", "right")'
    assert_includes renderer, 'root.prop("max_width", 720)'
    assert_includes renderer, 'root.prop("max_height", 900)'
    assert_includes renderer, "function hiddenX()"
    assert_includes renderer, "function hiddenY()"
    assert_includes renderer, 'root.prop("show_header", true)'
    assert_includes renderer, 'root.prop("show_close", true)'
    assert_includes renderer, 'modalSheetRoot.dismiss("close_button")'
    assert_includes renderer, 'reportDismiss("close_policy")'
    assert_includes renderer, "delegate: childDelegate"
    assert_includes renderer, 'property: modalSheetRoot.horizontalEdge ? "y" : "x"'
  end

  def test_snackbar_has_a_specific_timed_action_popup_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "snackbar"'
    assert_includes renderer, "id: snackbarComponent"
    assert_includes renderer, "id: snackbarRoot"
    assert_includes renderer, 'root.prop("position", "bottom_center")'
    assert_includes renderer, 'root.prop("duration", 4000)'
    assert_includes renderer, 'root.prop("persistent", false)'
    assert_includes renderer, "function pauseTimeout()"
    assert_includes renderer, "function resumeTimeout()"
    assert_includes renderer, "HoverHandler {"
    assert_includes renderer, "id: dismissTimer"
    assert_includes renderer, '"action", {}'
    assert_includes renderer, '"timeout", {}'
    assert_includes renderer, 'snackbarRoot.dismiss("action")'
    assert_includes renderer, 'snackbarRoot.dismiss("timeout")'
  end

  def test_banner_has_a_specific_severity_notice_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "banner"'
    assert_includes renderer, "id: bannerComponent"
    assert_includes renderer, "id: bannerRoot"
    assert_includes renderer, "QQC.Pane {"
    assert_includes renderer, 'root.prop("severity", "info")'
    assert_includes renderer, 'return "circle_check"'
    assert_includes renderer, 'return "warning"'
    assert_includes renderer, 'return "circle_xmark"'
    assert_includes renderer, 'root.prop("title", "")'
    assert_includes renderer, 'root.prop("message", "")'
    assert_includes renderer, 'root.prop("action_text", "")'
    assert_includes renderer, 'root.prop("dismissible", true)'
    assert_includes renderer, '"action", {}'
    assert_includes renderer, '"dismiss", {}'
    assert_includes renderer, 'visible ? "show" : "hide"'
  end

  def test_toast_has_a_specific_timed_severity_popup_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "toast"'
    assert_includes renderer, "id: toastComponent"
    assert_includes renderer, "id: toastRoot"
    assert_includes renderer, 'root.prop("position", "top_right")'
    assert_includes renderer, 'root.prop("severity", "info")'
    assert_includes renderer, 'root.prop("duration", 3500)'
    assert_includes renderer, "function severityIcon()"
    assert_includes renderer, "function severityColor()"
    assert_includes renderer, "function pauseTimeout()"
    assert_includes renderer, "HoverHandler {"
    assert_includes renderer, "id: dismissTimer"
    assert_includes renderer, '"click", {}'
    assert_includes renderer, '"timeout", {}'
    assert_includes renderer, 'toastRoot.dismiss("click")'
    assert_includes renderer, 'toastRoot.dismiss("timeout")'
  end

  def test_busy_indicator_has_a_specific_native_activity_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "busy_indicator"'
    assert_includes renderer, "id: busyIndicatorComponent"
    assert_includes renderer, "QQC.BusyIndicator {"
    assert_includes renderer, 'root.prop("running", true)'
    assert_includes renderer, 'root.prop("width", 48)'
    assert_includes renderer, 'root.prop("height", 48)'
    assert_includes renderer, 'palette.highlight: root.prop("color", Color.accent)'
    assert_includes renderer, 'Accessible.name: String(root.prop("accessible_name", "Loading"))'
    assert_includes renderer, '"running_change", { value: running }'
  end

  def test_progress_ring_has_a_specific_circular_progress_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "progress_ring"'
    assert_includes renderer, "id: progressRingComponent"
    assert_includes renderer, "id: ringRoot"
    assert_includes renderer, "Canvas {"
    assert_includes renderer, 'root.prop("minimum", 0)'
    assert_includes renderer, 'root.prop("maximum", 1)'
    assert_includes renderer, 'root.prop("indeterminate", false)'
    assert_includes renderer, 'root.prop("thickness", 5)'
    assert_includes renderer, 'root.prop("start_angle", -90)'
    assert_includes renderer, 'root.prop("clockwise", true)'
    assert_includes renderer, "context.arc(centerX, centerY, radius, start, end"
    assert_includes renderer, "RotationAnimator {"
    assert_includes renderer, "Behavior on displayedProgress"
    assert_includes renderer, 'root.prop("label_format", "{percent}%")'
    assert_includes renderer, '"value_change", {'
    assert_includes renderer, "normalized: normalizedValue"
  end

  def test_skeleton_has_a_specific_multivariant_shimmer_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "skeleton"'
    assert_includes renderer, "id: skeletonComponent"
    assert_includes renderer, "id: skeletonRoot"
    assert_includes renderer, 'root.prop("variant", "rectangle")'
    assert_includes renderer, 'root.prop("lines", 3)'
    assert_includes renderer, 'root.prop("line_height", 14)'
    assert_includes renderer, 'root.prop("last_line_width", 0.68)'
    assert_includes renderer, 'skeletonRoot.variant === "circle"'
    assert_includes renderer, "GradientStop { position: 0.5; color: skeletonRoot.highlightColor }"
    assert_includes renderer, 'root.prop("direction", "left_to_right")'
    assert_includes renderer, "NumberAnimation on shimmerProgress"
    assert_includes renderer, 'root.prop("duration", 1200)'
    assert_includes renderer, '"animation_change", { running: shimmerRunning }'
  end

  def test_item_delegate_has_a_specific_native_collection_row_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "item_delegate"'
    assert_includes renderer, "id: itemDelegateComponent"
    assert_includes renderer, "QQC.ItemDelegate {"
    assert_includes renderer, 'root.prop("description", "")'
    assert_includes renderer, 'root.prop("icon_source", "")'
    assert_includes renderer, 'root.prop("trailing_text", "")'
    assert_includes renderer, 'root.prop("show_indicator", false)'
    assert_includes renderer, 'root.prop("selected", false)'
    assert_includes renderer, 'root.prop("checkable", false)'
    assert_includes renderer, 'root.prop("checked", false)'
    assert_includes renderer, 'root.prop("value", text)'
    assert_includes renderer, '"click", payload'
    assert_includes renderer, '"activate", payload'
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
  end

  def test_check_delegate_has_a_specific_native_tristate_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "check_delegate"'
    assert_includes renderer, "id: checkDelegateComponent"
    assert_includes renderer, "QQC.CheckDelegate {"
    assert_includes renderer, 'root.prop("tristate", false)'
    assert_includes renderer, 'root.prop("check_state"'
    assert_includes renderer, 'return Qt.PartiallyChecked'
    assert_includes renderer, 'return "partial"'
    assert_includes renderer, "check_state: checkStateName()"
    assert_includes renderer, 'root.prop("indicator_size", 22)'
    assert_includes renderer, 'checkRoot.checkState === Qt.PartiallyChecked ? "−"'
    assert_includes renderer, '"click", payload'
    assert_includes renderer, '"activate", payload'
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
  end

  def test_radio_delegate_has_a_specific_native_exclusive_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "radio_delegate"'
    assert_includes renderer, "id: radioDelegateComponent"
    assert_includes renderer, "QQC.RadioDelegate {"
    assert_includes renderer, 'root.prop("checked", false)'
    assert_includes renderer, 'root.prop("auto_exclusive", true)'
    assert_includes renderer, 'root.prop("indicator_size", 22)'
    assert_includes renderer, 'root.prop("dot_size", Math.max(8, parent.width * 0.48))'
    assert_includes renderer, 'root.prop("value", text)'
    assert_includes renderer, '"click", payload'
    assert_includes renderer, '"activate", payload'
    assert_includes renderer, '"select", payload'
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
  end

  def test_switch_delegate_has_a_specific_native_animated_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "switch_delegate"'
    assert_includes renderer, "id: switchDelegateComponent"
    assert_includes renderer, "QQC.SwitchDelegate {"
    assert_includes renderer, 'root.prop("checked", false)'
    assert_includes renderer, 'root.prop("indicator_width", 44)'
    assert_includes renderer, 'root.prop("indicator_height", 24)'
    assert_includes renderer, 'root.prop("checked_track_color"'
    assert_includes renderer, 'root.prop("thumb_size", parent.height - 4)'
    assert_includes renderer, "Behavior on x"
    assert_includes renderer, "ColorAnimation { duration: Number(root.prop(\"duration\", 140)) }"
    assert_includes renderer, 'root.prop("value", text)'
    assert_includes renderer, '"activate", payload'
    assert_includes renderer, '"toggle", payload'
    assert_includes renderer, '"change", payload'
  end

  def test_swipe_delegate_has_a_specific_native_action_lane_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "swipe_delegate"'
    assert_includes renderer, "id: swipeDelegateComponent"
    assert_includes renderer, "QQC.SwipeDelegate {"
    assert_includes renderer, 'root.prop("left_action", "")'
    assert_includes renderer, 'root.prop("right_action", "")'
    assert_includes renderer, 'root.prop("opened_side", "none")'
    assert_includes renderer, "swipe.open(QQC.SwipeDelegate.Left)"
    assert_includes renderer, "swipe.open(QQC.SwipeDelegate.Right)"
    assert_includes renderer, "swipe.left: hasLeftAction ? leftActionComponent : null"
    assert_includes renderer, "swipe.right: hasRightAction ? rightActionComponent : null"
    assert_includes renderer, 'QQC.SwipeDelegate.onClicked: swipeRoot.triggerAction("left")'
    assert_includes renderer, 'QQC.SwipeDelegate.onClicked: swipeRoot.triggerAction("right")'
    assert_includes renderer, '"swipe_position", {'
    assert_includes renderer, '"swipe_complete", {'
    assert_includes renderer, '"swipe_open", {'
    assert_includes renderer, '"swipe_close", {}'
  end

  def test_grid_view_has_a_specific_native_virtualized_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "grid_view"'
    assert_includes renderer, "id: gridViewComponent"
    assert_includes renderer, "id: gridControl"
    assert_includes renderer, "GridView {"
    assert_includes renderer, 'root.prop("items", [])'
    assert_includes renderer, 'root.prop("key_field", "id")'
    assert_includes renderer, 'root.prop("cell_width", 160)'
    assert_includes renderer, 'root.prop("cell_height", 120)'
    assert_includes renderer, "GridView.FlowTopToBottom"
    assert_includes renderer, "GridView.SnapToRow"
    assert_includes renderer, "Flickable.StopAtBounds"
    assert_includes renderer, 'root.prop("key_navigation_wraps", false)'
    assert_includes renderer, "Keys.onReturnPressed"
    assert_includes renderer, '"activate", payload'
    assert_includes renderer, '"current_change", payload'
    assert_includes renderer, '"count_change", { value: count }'
    assert_includes renderer, '"movement_start", { x: contentX, y: contentY }'
    assert_includes renderer, '"movement_end", { x: contentX, y: contentY }'
  end

  def test_table_view_has_a_specific_dynamic_native_table_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "table_view"'
    assert_includes renderer, "id: tableViewComponent"
    assert_includes renderer, "id: tableControl"
    assert_includes renderer, "TableView {"
    assert_includes renderer, 'root.prop("rows", [])'
    assert_includes renderer, 'root.prop("columns", [])'
    assert_includes renderer, 'Qt.createQmlObject(modelSource(), tableRoot, "ZuiDynamicTableModel")'
    assert_includes renderer, 'TableModelColumn { display:'
    assert_includes renderer, "created.rows = normalizedRows()"
    assert_includes renderer, "ItemSelectionModel {"
    assert_includes renderer, "TableView.SelectRows"
    assert_includes renderer, "TableView.ExtendedSelection"
    assert_includes renderer, "TableView.DoubleTapped"
    assert_includes renderer, "delegate: QQC.ItemDelegate {"
    assert_includes renderer, "selected = tableSelection.isSelected(modelIndex)"
    assert_includes renderer, "tableSelection.setCurrentIndex(modelIndex, ItemSelectionModel.ClearAndSelect)"
    refute_includes source("Components/Builtins/TableView.qml"), "QQC.TableViewDelegate"
    assert_includes renderer, "TableView.editDelegate: FocusScope {"
    assert_includes renderer, "tableRoot.tableModel.setData(index, editor.text, Qt.EditRole)"
    assert_includes renderer, '"cell_click", tableRoot.cellPayload'
    assert_includes renderer, '"cell_double_click", payload'
    assert_includes renderer, '"selection_change", payload'
    assert_includes renderer, '"edit",'
    assert_includes renderer, '"row_count_change", { value: rows }'
    assert_includes renderer, '"column_count_change", { value: columns }'
  end

  def test_tree_view_has_a_specific_dynamic_native_tree_renderer
    renderer = source("ControlNode.qml")

    assert_includes renderer, 'node.type === "tree_view"'
    assert_includes renderer, "id: treeViewComponent"
    assert_includes renderer, "TreeView {"
    assert_includes renderer, 'root.prop("children_field", "children")'
    assert_includes renderer, 'Qt.createQmlObject(modelSource(), treeRoot, "ZuiDynamicTreeModel")'
    assert_includes renderer, 'TreeModel {'
    assert_includes renderer, 'normalized.rows = []'
    assert_includes renderer, "delegate: QQC.TreeViewDelegate {"
    assert_includes renderer, "treeControl.expandToIndex(expandedIndex)"
    assert_includes renderer, "treeControl.expandRecursively(rootCell.y, depth - 1)"
    assert_includes renderer, "treeModel.index(cleanPath(expandedPaths[index]), 0)"
    assert_includes renderer, "current = current.parent"
    assert_includes renderer, "TableView.editDelegate: FocusScope {"
    assert_includes renderer, '"expand",'
    assert_includes renderer, '"collapse",'
    assert_includes renderer, '"selection_change", payload'
  end
end
