import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "Theme"
import "Controls" as ZuiControls

Loader {
  id: root

  property var bridge: null
  property string surfaceName: ""
  property string controlId: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property string iconFontFamily: Fonts.iconFamily
  readonly property string brandIconFontFamily: Fonts.brandIconFamily

  // Shared recursive delegates are framework infrastructure. Individual built-in
  // renderers consume these without duplicating ControlNode's lifecycle wiring.
  readonly property Component childDelegateComponent: childDelegate
  readonly property Component rowChildDelegateComponent: rowChildDelegate
  readonly property Component columnChildDelegateComponent: columnChildDelegate
  readonly property Component layoutChildDelegateComponent: layoutChildDelegate
  readonly property Component splitChildDelegateComponent: splitChildDelegate

  readonly property var node: {
    var currentRevision = bridge ? bridge.revision : 0
    return bridge ? bridge.nodeFor(controlId) : null
  }

  readonly property bool builtIn: ["text", "label", "rich_text", "markdown", "selectable_text", "icon", "tooltip", "button", "round_button", "tool_button", "delay_button", "row", "column", "container", "image", "vector_image", "model_view_3d", "font_loader", "text_metrics", "animated_image", "video", "audio", "avatar", "badge", "chip", "spacer",
    "grid", "row_layout", "column_layout", "grid_layout", "flow", "center", "card", "border_overlay", "aspect_ratio", "constrained_box", "fitted_box", "wrap", "split_view", "stack_layout", "layout_item_proxy", "loader", "flickable", "focus_scope", "flipable", "border_image", "window", "application_window",
    "stack", "scroll", "rectangle", "page", "pane", "frame", "group_box", "tabs", "tab_bar", "tab_button", "page_indicator", "stack_view", "swipe_view", "drawer", "navigation_rail", "breadcrumb", "pagination", "expansion_panel", "accordion", "tool_bar", "tool_separator", "menu", "menu_item", "menu_separator", "menu_bar", "context_menu", "popup", "dialog", "alert_dialog", "message_dialog", "bottom_sheet", "modal_sheet", "snackbar", "banner", "toast", "busy_indicator", "progress_ring", "skeleton", "item_delegate", "check_delegate", "radio_delegate", "switch_delegate", "swipe_delegate", "grid_view", "table_view", "tree_view", "action_button", "bar_icon_button", "bar_indicator", "toggle", "checkbox", "radio_button", "radio_group", "toggle_switch", "text_field",
    "number_field", "text_area", "search_field", "password_field", "slider", "range_slider", "dial", "spin_box", "double_spin_box", "color_picker", "date_picker", "time_picker", "file_picker", "folder_picker", "font_picker", "dialog_button_box", "action", "action_group", "dropdown", "multi_select", "button_group", "progress", "line_chart", "area_chart", "bar_chart", "separator", "divider",
    "section_header", "searchable_dropdown", "confirm_dialog", "panel_hero", "optical_glyph",
    "cursor_surface", "widget_button", "list_view", "key_catcher", "canvas", "shape", "line", "path", "circle", "gradient", "shader_effect", "shader_effect_source", "multi_effect", "rectangular_shadow", "opacity_mask", "blur", "drop_shadow", "colorize", "glow", "particle_system",
    "data_table", "horizontal_header", "vertical_header", "table_view_delegate", "tree_view_delegate", "horizontal_header_delegate", "vertical_header_delegate", "reorderable_list", "carousel", "calendar", "month_grid", "week_number_column", "day_of_week_row", "tumbler",
    "stacked_bar_chart", "pie_chart", "donut_chart", "scatter_chart", "bubble_chart", "radar_chart", "heatmap", "sparkline", "gauge", "radial_gauge", "histogram", "candlestick_chart", "legend",
    "drag_area", "drop_area", "pinch_area", "hover_area", "selection_rectangle", "scroll_bar", "scroll_indicator",
    "animation", "number_animation", "color_animation", "rotation_animation", "vector_animation", "path_animation", "property_animation", "pause_animation", "script_action", "property_action", "parallel_animation", "sequential_animation", "spring_animation", "smoothed_animation", "anchor_animation", "parent_animation", "opacity_animator", "rotation_animator", "scale_animator", "x_animator", "y_animator", "uniform_animator", "frame_animation", "animation_controller", "behavior", "transition", "state", "state_group", "property_changes", "anchor_changes", "parent_change", "timer",
    "media_player", "video_output", "sound_effect", "camera", "capture_session", "image_capture", "media_recorder", "audio_input", "audio_output", "media_devices", "screen_capture", "window_capture",
    "list_model", "delegate_model", "delegate_model_group", "sort_filter_proxy_model", "folder_list_model", "settings", "standard_paths", "clipboard"].indexOf(node ? node.type : "") >= 0
  readonly property bool structuralContainer: ["row", "column", "container", "grid", "row_layout",
    "column_layout", "grid_layout", "flow", "center", "card", "stack", "scroll", "rectangle", "aspect_ratio", "constrained_box", "fitted_box", "wrap", "split_view", "stack_layout", "loader", "flickable", "focus_scope", "flipable", "border_image", "key_catcher", "shader_effect", "shader_effect_source", "multi_effect", "rectangular_shadow", "opacity_mask", "blur", "drop_shadow", "colorize", "glow", "drag_area", "drop_area", "pinch_area", "hover_area", "capture_session"]
    .indexOf(node ? node.type : "") >= 0
  property string loadedAdapterKey: ""
  property string lastComponentErrorKey: ""

  function prop(name, fallback) {
    var props = node && node.props ? node.props : null
    var value = props ? props[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function iconGlyph(name) {
    var icons = {
      ruby: "\uf3a5",
      phone: "\uf3cd",
      plus: "\uf067",
      minus: "\uf068",
      reset: "\uf2f9", refresh: "\uf2f9",
      house: "\uf015", gear: "\uf013", search: "\uf002", xmark: "\uf00d", check: "\uf00c",
      menu: "\uf0c9", user: "\uf007", bell: "\uf0f3", wifi: "\uf1eb", bluetooth: "\uf293",
      volume_high: "\uf028", volume_low: "\uf027", volume_off: "\uf026",
      play: "\uf04b", pause: "\uf04c", stop: "\uf04d", trash: "\uf1f8", edit: "\uf044",
      folder: "\uf07b", file: "\uf15b", download: "\uf019", upload: "\uf093", link: "\uf0c1",
      lock: "\uf023", unlock: "\uf09c", eye: "\uf06e", eye_slash: "\uf070",
      star: "\uf005", heart: "\uf004", info: "\uf129", warning: "\uf071",
      circle_info: "\uf05a", circle_check: "\uf058", circle_xmark: "\uf057",
      arrow_left: "\uf060", arrow_right: "\uf061", arrow_up: "\uf062", arrow_down: "\uf063",
      chevron_left: "\uf053", chevron_right: "\uf054", chevron_up: "\uf077", chevron_down: "\uf078",
      calendar: "\uf133", clock: "\uf017", camera: "\uf030", image: "\uf03e", music: "\uf001",
      terminal: "\uf120", code: "\uf121", copy: "\uf0c5", save: "\uf0c7", power: "\uf011",
      globe: "\uf0ac", location: "\uf3c5", pin: "\uf08d", android: "\uf17b", apple: "\uf179"
    }
    var key = String(name || "")
    return icons[key] || key
  }

  function iconFontFamilyFor(name) {
    var key = String(name || "")
    return ["bluetooth", "android", "apple"].indexOf(key) >= 0
      ? brandIconFontFamily : iconFontFamily
  }

  function escapeAutoText(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
  }

  function easingType(name) {
    var easings = {
      linear: Easing.Linear,
      in_quad: Easing.InQuad, out_quad: Easing.OutQuad, in_out_quad: Easing.InOutQuad,
      in_cubic: Easing.InCubic, out_cubic: Easing.OutCubic, in_out_cubic: Easing.InOutCubic,
      in_back: Easing.InBack, out_back: Easing.OutBack, in_out_back: Easing.InOutBack,
      in_elastic: Easing.InElastic, out_elastic: Easing.OutElastic, in_out_elastic: Easing.InOutElastic,
      in_bounce: Easing.InBounce, out_bounce: Easing.OutBounce, in_out_bounce: Easing.InOutBounce
    }
    return easings[String(name || "")] === undefined ? Easing.InOutQuad : easings[String(name)]
  }

  function layoutAlignment(name, fallback) {
    var value = String(name || fallback || "center")
    if (value === "start" || value === "left" || value === "top") return Qt.AlignLeft | Qt.AlignTop
    if (value === "end" || value === "right" || value === "bottom") return Qt.AlignRight | Qt.AlignBottom
    if (value === "left_center") return Qt.AlignLeft | Qt.AlignVCenter
    if (value === "right_center") return Qt.AlignRight | Qt.AlignVCenter
    if (value === "top_center") return Qt.AlignTop | Qt.AlignHCenter
    if (value === "bottom_center") return Qt.AlignBottom | Qt.AlignHCenter
    return Qt.AlignCenter
  }

  function findRenderedItem(targetId) {
    var ancestor = root
    while (ancestor.parent) ancestor = ancestor.parent
    return findRenderedItemBelow(ancestor, String(targetId || ""))
  }

  function findRenderedItemBelow(object, targetId) {
    if (!object || targetId === "") return null
    if (object !== root && object.controlId !== undefined && String(object.controlId) === targetId)
      return object.item || object
    var descendants = object.children || []
    for (var index = 0; index < descendants.length; index++) {
      var result = findRenderedItemBelow(descendants[index], targetId)
      if (result) return result
    }
    return null
  }

  function subscribed(eventName) {
    return node && Array.isArray(node.events) && node.events.indexOf(eventName) >= 0
  }

  function componentError(code, message, payload) {
    var componentType = node ? String(node.type) : "component"
    var errorCode = String(code || "component_error")
    var errorMessage = String(message || "Component failed")
    var errorKey = componentType + ":" + errorCode + ":" + errorMessage
    if (errorKey === lastComponentErrorKey) return
    lastComponentErrorKey = errorKey
    if (bridge && bridge.reportComponentError)
      bridge.reportComponentError(surfaceName, controlId, componentType, errorCode, errorMessage)
    if (!subscribed("error")) return
    var eventPayload = payload && typeof payload === "object" ? payload : ({})
    eventPayload.code = errorCode
    eventPayload.message = errorMessage
    bridge.sendEvent(surfaceName, controlId, "error", eventPayload)
  }

  function configureFace(face, childNode) {
    if (!face || !childNode) return
    face.bridge = bridge
    face.surfaceName = surfaceName
    face.controlId = String(childNode.id)
    face.foreground = foreground
    face.fontFamily = fontFamily
  }

  function borderImageTileMode(value) {
    var mode = String(value || "stretch")
    if (mode === "repeat") return BorderImage.Repeat
    if (mode === "round") return BorderImage.Round
    return BorderImage.Stretch
  }

  function assetUrl(value) {
    var source = String(value || "")
    if (source === "") return ""
    if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(source)) return source
    if (source[0] === "/") return "file://" + source
    return bridge && bridge.projectDir ? bridge.projectDir + "/" + source : Qt.resolvedUrl(source)
  }

  function builtInSource(typeName) {
    var parts = String(typeName || "").split("_")
    for (var index = 0; index < parts.length; index++)
      parts[index] = parts[index].charAt(0).toUpperCase() + parts[index].slice(1)
    return Qt.resolvedUrl("Components/Builtins/" + parts.join("") + ".qml")
  }

  function ensureAdapterLoaded() {
    if (!node) {
      loadedAdapterKey = ""
      if (source !== "") source = ""
      return
    }
    var adapterSource = builtIn ? builtInSource(node.type) : bridge.componentSource(node.type)
    var adapterKey = String(node.type) + ":" + String(adapterSource)
    if (loadedAdapterKey === adapterKey && item) return
    loadedAdapterKey = adapterKey
    if (builtIn) setSource(adapterSource, { renderer: root })
    else source = adapterSource
  }

  function nativeDefinition() {
    return bridge && node ? bridge.componentDefinition(node.type) : null
  }

  function optionValue(option) {
    return option !== null && typeof option === "object" && option.value !== undefined ? option.value : option
  }

  function optionLabel(option) {
    return option !== null && typeof option === "object" && option.label !== undefined ? option.label : optionValue(option)
  }

  function syncNativeProperties() {
    var definition = nativeDefinition()
    if (!item || !definition || !definition.autoBind) return
    var props = node && node.props ? node.props : ({})
    var common = { visible: true, enabled: true, opacity: true, scale: true, rotation: true, z: true, width: true, height: true }
    for (var protocolName in props) {
      if (common[protocolName]) continue
      var qmlName = definition.propertyMap[protocolName] || protocolName
      if (item.hasOwnProperty(qmlName)) item[qmlName] = props[protocolName]
    }
  }

  function nativeEventPayload(args) {
    if (args.length === 0) return ({})
    if (args.length === 1 && args[0] !== null && typeof args[0] === "object" && !Array.isArray(args[0])) return args[0]
    var values = []
    for (var i = 0; i < args.length; i++) {
      var value = args[i]
      if (value === null || typeof value === "string" || typeof value === "number" || typeof value === "boolean"
          || Array.isArray(value)) values.push(value)
      else values.push(String(value))
    }
    return values.length === 1 ? { value: values[0] } : { arguments: values }
  }

  function connectNativeEvents() {
    var definition = nativeDefinition()
    if (!item || !definition || !definition.autoBind || !node || !Array.isArray(node.events)) return
    for (let i = 0; i < node.events.length; i++) {
      let protocolName = String(node.events[i])
      if (protocolName === "mount" || protocolName === "unmount") continue
      let qmlName = definition.eventMap[protocolName] || protocolName
      let signal = item[qmlName]
      if (signal && typeof signal.connect === "function") {
        signal.connect(function() {
          root.bridge.sendEvent(root.surfaceName, root.controlId, protocolName, root.nativeEventPayload(arguments))
        })
      }
    }
  }

  function runTransition() {
    var transitions = node && Array.isArray(node.transitions)
      ? node.transitions
      : (node && node.transition ? [node.transition] : [])
    if (!item || transitions.length === 0) return
    for (var transitionIndex = 0; transitionIndex < transitions.length; transitionIndex++)
      runTrack(transitions[transitionIndex])
  }

  function runTrack(transition) {
    var commonProperties = ["opacity", "scale", "rotation", "z", "width", "height"]
    var definition = nativeDefinition()
    var animationProperty = definition && definition.propertyMap[transition.property]
      ? definition.propertyMap[transition.property] : transition.property
    var animationTarget = commonProperties.indexOf(transition.property) >= 0 ? root : item
    if (!animationTarget.hasOwnProperty(animationProperty)) return
    if (transition.from === undefined || transition.from === null) return
    var animation = propertyAnimationFactory.createObject(root, {
      target: animationTarget,
      property: String(animationProperty),
      from: transition.from,
      to: transition.to,
      duration: Number(transition.duration)
    })
    animation.easing.type = easingType(transition.easing)
    var delay = Number(transition.delay || 0)
    if (delay > 0) delayedAnimationFactory.createObject(root, { interval: delay, animation: animation }).start()
    else animation.start()
  }

  visible: node !== null && prop("visible", true) !== false
  enabled: prop("enabled", true) !== false
  opacity: Number(prop("opacity", 1))
  scale: Number(prop("scale", 1))
  rotation: Number(prop("rotation", 0))
  z: Number(prop("z", 0))
  sourceComponent: null
  source: ""
  onLoaded: {
    lastComponentErrorKey = ""
    if (!item) return
    if (builtIn && item.hasOwnProperty("renderer")) {
      item.renderer = root
    } else if (!builtIn) {
      if (item.hasOwnProperty("bridge")) item.bridge = bridge
      if (item.hasOwnProperty("surfaceName")) item.surfaceName = surfaceName
      if (item.hasOwnProperty("controlId")) item.controlId = controlId
      if (item.hasOwnProperty("node")) item.node = node
      syncNativeProperties()
      connectNativeEvents()
    }
    runTransition()
    if (subscribed("mount")) bridge.sendEvent(surfaceName, controlId, "mount", {})
  }
  onStatusChanged: {
    if (status === Loader.Error)
      componentError("component_load_failed", "Unable to load the declared " + (node ? node.type : "component") + " renderer", { source: String(source) })
  }
  onNodeChanged: {
    Qt.callLater(ensureAdapterLoaded)
    if (item && !builtIn && item.hasOwnProperty("node")) item.node = node
    if (!builtIn) syncNativeProperties()
    Qt.callLater(runTransition)
  }
  Component.onCompleted: Qt.callLater(ensureAdapterLoaded)

  TapHandler {
    enabled: root.structuralContainer && root.subscribed("click")
    onTapped: root.bridge.sendEvent(root.surfaceName, root.controlId, "click", {})
  }

  Repeater {
    id: nativeChildren
    parent: root.item && root.item.hasOwnProperty("contentHost") && root.item.contentHost
      ? root.item.contentHost
      : root
    model: !root.builtIn && root.node && root.nativeDefinition() && root.nativeDefinition().container
      && Array.isArray(root.node.children) ? root.node.children : []
    delegate: childDelegate
  }

  Component {
    id: propertyAnimationFactory
    PropertyAnimation { onStopped: destroy() }
  }

  Component {
    id: delayedAnimationFactory
    Timer {
      required property var animation
      repeat: false
      onTriggered: { animation.start(); destroy() }
    }
  }

  Component.onDestruction: {
    if (bridge && subscribed("unmount")) bridge.sendEvent(surfaceName, controlId, "unmount", {})
  }

  Component {
    id: splitChildDelegate
    Loader {
      required property var modelData
      QQC.SplitView.minimumWidth: Number(modelData.props && modelData.props.minimum_width !== undefined ? modelData.props.minimum_width : 0)
      QQC.SplitView.minimumHeight: Number(modelData.props && modelData.props.minimum_height !== undefined ? modelData.props.minimum_height : 0)
      QQC.SplitView.preferredWidth: Number(modelData.props && modelData.props.preferred_width !== undefined ? modelData.props.preferred_width : implicitWidth)
      QQC.SplitView.preferredHeight: Number(modelData.props && modelData.props.preferred_height !== undefined ? modelData.props.preferred_height : implicitHeight)
      QQC.SplitView.fillWidth: modelData.props && modelData.props.fill_width === true
      QQC.SplitView.fillHeight: modelData.props && modelData.props.fill_height === true
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: childDelegate
    Loader {
      required property var modelData
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: rowChildDelegate
    Loader {
      required property var modelData
      readonly property string crossAlignment: String(root.prop("alignment", "center"))
      anchors.top: crossAlignment === "start" || crossAlignment === "top" ? parent.top : undefined
      anchors.verticalCenter: crossAlignment === "center" ? parent.verticalCenter : undefined
      anchors.bottom: crossAlignment === "end" || crossAlignment === "bottom" ? parent.bottom : undefined
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: layoutChildDelegate
    Loader {
      required property var modelData
      readonly property var layoutProps: modelData && modelData.props ? modelData.props : ({})
      Layout.fillWidth: layoutProps.fill_width === true
      Layout.fillHeight: layoutProps.fill_height === true
      Layout.preferredWidth: layoutProps.preferred_width === undefined ? -1 : Number(layoutProps.preferred_width)
      Layout.preferredHeight: layoutProps.preferred_height === undefined ? -1 : Number(layoutProps.preferred_height)
      Layout.minimumWidth: layoutProps.minimum_width === undefined ? 0 : Number(layoutProps.minimum_width)
      Layout.minimumHeight: layoutProps.minimum_height === undefined ? 0 : Number(layoutProps.minimum_height)
      Layout.maximumWidth: layoutProps.maximum_width === undefined ? Infinity : Number(layoutProps.maximum_width)
      Layout.maximumHeight: layoutProps.maximum_height === undefined ? Infinity : Number(layoutProps.maximum_height)
      Layout.alignment: root.layoutAlignment(layoutProps.layout_alignment, root.prop("alignment", "center"))
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

  Component {
    id: columnChildDelegate
    Loader {
      required property var modelData
      readonly property string crossAlignment: String(root.prop("alignment", "start"))
      anchors.left: crossAlignment === "start" || crossAlignment === "left" ? parent.left : undefined
      anchors.horizontalCenter: crossAlignment === "center" ? parent.horizontalCenter : undefined
      anchors.right: crossAlignment === "end" || crossAlignment === "right" ? parent.right : undefined
      source: Qt.resolvedUrl("ControlNode.qml")
      onLoaded: {
        item.bridge = root.bridge
        item.surfaceName = root.surfaceName
        item.controlId = String(modelData.id)
        item.foreground = root.foreground
        item.fontFamily = root.fontFamily
      }
    }
  }

}
