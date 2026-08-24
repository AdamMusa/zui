import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "Theme"
import "Controls" as ZuiControls
import "Components/Builtins" as Builtins

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
    if (!node || sourceComponent !== null) {
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
  sourceComponent: {
    if (!node) return null
    if (node.type === "text") return textComponent
    if (node.type === "label") return labelComponent
    if (node.type === "rich_text") return richTextComponent
    if (node.type === "markdown") return markdownComponent
    if (node.type === "selectable_text") return selectableTextComponent
    if (node.type === "icon") return iconComponent
    if (node.type === "tooltip") return tooltipComponent
    if (node.type === "button") return buttonComponent
    if (node.type === "round_button") return roundButtonComponent
    if (node.type === "tool_button") return toolButtonComponent
    if (node.type === "delay_button") return delayButtonComponent
    if (node.type === "row") return rowComponent
    if (node.type === "column") return columnComponent
    if (node.type === "container") return containerComponent
    if (node.type === "image") return imageComponent
    if (node.type === "vector_image") return vectorImageComponent
    if (node.type === "font_loader") return fontLoaderComponent
    if (node.type === "text_metrics") return textMetricsComponent
    if (node.type === "animated_image") return animatedImageComponent
    if (node.type === "avatar") return avatarComponent
    if (node.type === "badge") return badgeComponent
    if (node.type === "chip") return chipComponent
    if (node.type === "spacer") return spacerComponent
    if (node.type === "grid") return gridComponent
    if (node.type === "row_layout") return rowLayoutComponent
    if (node.type === "column_layout") return columnLayoutComponent
    if (node.type === "grid_layout") return gridLayoutComponent
    if (node.type === "flow") return flowComponent
    if (node.type === "center") return centerComponent
    if (node.type === "card") return cardComponent
    if (node.type === "border_overlay") return borderOverlayComponent
    if (node.type === "aspect_ratio") return aspectRatioComponent
    if (node.type === "constrained_box") return constrainedBoxComponent
    if (node.type === "fitted_box") return fittedBoxComponent
    if (node.type === "wrap") return wrapComponent
    if (node.type === "split_view") return splitViewComponent
    if (node.type === "stack_layout") return stackLayoutComponent
    if (node.type === "layout_item_proxy") return layoutItemProxyComponent
    if (node.type === "loader") return lazyLoaderComponent
    if (node.type === "flickable") return flickableComponent
    if (node.type === "focus_scope") return focusScopeComponent
    if (node.type === "flipable") return flipableComponent
    if (node.type === "border_image") return borderImageComponent
    if (node.type === "window") return windowComponent
    if (node.type === "application_window") return applicationWindowComponent
    if (node.type === "page") return pageComponent
    if (node.type === "pane") return paneComponent
    if (node.type === "frame") return frameComponent
    if (node.type === "group_box") return groupBoxComponent
    if (node.type === "tabs") return tabsComponent
    if (node.type === "tab_bar") return tabBarComponent
    if (node.type === "tab_button") return tabButtonComponent
    if (node.type === "page_indicator") return pageIndicatorComponent
    if (node.type === "stack_view") return stackViewComponent
    if (node.type === "swipe_view") return swipeViewComponent
    if (node.type === "drawer") return drawerComponent
    if (node.type === "navigation_rail") return navigationRailComponent
    if (node.type === "breadcrumb") return breadcrumbComponent
    if (node.type === "pagination") return paginationComponent
    if (node.type === "expansion_panel") return expansionPanelComponent
    if (node.type === "accordion") return accordionComponent
    if (node.type === "tool_bar") return toolBarComponent
    if (node.type === "tool_separator") return toolSeparatorComponent
    if (node.type === "menu") return menuComponent
    if (node.type === "menu_item") return menuItemComponent
    if (node.type === "menu_separator") return menuSeparatorComponent
    if (node.type === "menu_bar") return menuBarComponent
    if (node.type === "context_menu") return contextMenuComponent
    if (node.type === "popup") return popupComponent
    if (node.type === "dialog") return dialogComponent
    if (node.type === "alert_dialog") return alertDialogComponent
    if (node.type === "message_dialog") return messageDialogComponent
    if (node.type === "bottom_sheet") return bottomSheetComponent
    if (node.type === "modal_sheet") return modalSheetComponent
    if (node.type === "snackbar") return snackbarComponent
    if (node.type === "banner") return bannerComponent
    if (node.type === "toast") return toastComponent
    if (node.type === "busy_indicator") return busyIndicatorComponent
    if (node.type === "progress_ring") return progressRingComponent
    if (node.type === "skeleton") return skeletonComponent
    if (node.type === "item_delegate") return itemDelegateComponent
    if (node.type === "check_delegate") return checkDelegateComponent
    if (node.type === "radio_delegate") return radioDelegateComponent
    if (node.type === "switch_delegate") return switchDelegateComponent
    if (node.type === "swipe_delegate") return swipeDelegateComponent
    if (node.type === "grid_view") return gridViewComponent
    if (node.type === "table_view") return tableViewComponent
    if (node.type === "tree_view") return treeViewComponent
    if (node.type === "canvas") return canvasComponent
    if (node.type === "shape") return shapeComponent
    if (node.type === "line") return lineComponent
    if (node.type === "path") return pathComponent
    if (node.type === "circle") return circleComponent
    if (node.type === "gradient") return gradientComponent
    if (node.type === "shader_effect") return shaderEffectComponent
    if (node.type === "shader_effect_source") return shaderEffectSourceComponent
    if (node.type === "multi_effect") return multiEffectComponent
    if (node.type === "opacity_mask") return opacityMaskComponent
    if (node.type === "blur") return blurComponent
    if (node.type === "drop_shadow") return dropShadowComponent
    if (node.type === "colorize") return colorizeComponent
    if (node.type === "glow") return glowComponent
    if (node.type === "particle_system") return particleSystemComponent
    if (node.type === "stack") return stackComponent
    if (node.type === "scroll") return scrollComponent
    if (node.type === "rectangle") return rectangleComponent
    if (node.type === "action_button") return actionButtonComponent
    if (node.type === "bar_icon_button") return barIconButtonComponent
    if (node.type === "bar_indicator") return barIndicatorComponent
    if (node.type === "toggle") return toggleComponent
    if (node.type === "checkbox") return checkboxComponent
    if (node.type === "radio_button") return radioButtonComponent
    if (node.type === "radio_group") return radioGroupComponent
    if (node.type === "toggle_switch") return toggleSwitchComponent
    if (node.type === "text_field") return textFieldComponent
    if (node.type === "number_field") return numberFieldComponent
    if (node.type === "text_area") return textAreaComponent
    if (node.type === "search_field") return searchFieldComponent
    if (node.type === "password_field") return passwordFieldComponent
    if (node.type === "slider") return sliderComponent
    if (node.type === "range_slider") return rangeSliderComponent
    if (node.type === "dial") return dialComponent
    if (node.type === "spin_box") return spinBoxComponent
    if (node.type === "double_spin_box") return doubleSpinBoxComponent
    if (node.type === "color_picker") return colorPickerComponent
    if (node.type === "date_picker") return datePickerComponent
    if (node.type === "time_picker") return timePickerComponent
    if (node.type === "file_picker") return filePickerComponent
    if (node.type === "folder_picker") return folderPickerComponent
    if (node.type === "font_picker") return fontPickerComponent
    if (node.type === "dialog_button_box") return dialogButtonBoxComponent
    if (node.type === "action") return actionComponent
    if (node.type === "action_group") return actionGroupComponent
    if (node.type === "dropdown") return dropdownComponent
    if (node.type === "multi_select") return multiSelectComponent
    if (node.type === "button_group") return buttonGroupComponent
    if (node.type === "progress") return progressComponent
    if (node.type === "line_chart") return lineChartComponent
    if (node.type === "area_chart") return areaChartComponent
    if (node.type === "bar_chart") return barChartComponent
    if (node.type === "separator") return separatorComponent
    if (node.type === "divider") return dividerComponent
    if (node.type === "section_header") return sectionHeaderComponent
    if (node.type === "searchable_dropdown") return searchableDropdownComponent
    if (node.type === "confirm_dialog") return confirmDialogComponent
    if (node.type === "panel_hero") return panelHeroComponent
    if (node.type === "optical_glyph") return opticalGlyphComponent
    if (node.type === "cursor_surface") return cursorSurfaceComponent
    if (node.type === "widget_button") return widgetButtonComponent
    if (node.type === "list_view") return listViewComponent
    if (node.type === "key_catcher") return keyCatcherComponent
    return null
  }
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
  onSourceComponentChanged: Qt.callLater(ensureAdapterLoaded)
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
    id: textComponent
    Builtins.Text { renderer: root }
  }

  Component {
    id: labelComponent
    Builtins.Label { renderer: root }
  }

  Component {
    id: richTextComponent
    Builtins.RichText { renderer: root }
  }

  Component {
    id: markdownComponent
    Builtins.Markdown { renderer: root }
  }

  Component {
    id: selectableTextComponent
    Builtins.SelectableText { renderer: root }
  }

  Component {
    id: iconComponent
    Builtins.Icon { renderer: root }
  }

  Component {
    id: tooltipComponent
    Builtins.Tooltip { renderer: root }
  }

  Component {
    id: buttonComponent
    Builtins.Button { renderer: root }
  }

  Component {
    id: roundButtonComponent
    Builtins.RoundButton { renderer: root }
  }

  Component {
    id: toolButtonComponent
    Builtins.ToolButton { renderer: root }
  }

  Component {
    id: delayButtonComponent
    Builtins.DelayButton { renderer: root }
  }

  Component {
    id: rowComponent
    Builtins.Row { renderer: root }
  }

  Component {
    id: columnComponent
    Builtins.Column { renderer: root }
  }

  Component {
    id: containerComponent
    Builtins.Container { renderer: root }
  }

  Component {
    id: imageComponent
    Builtins.Image { renderer: root }
  }

  Component {
    id: vectorImageComponent
    Builtins.VectorImage { renderer: root }
  }

  Component {
    id: fontLoaderComponent
    Builtins.FontLoader { renderer: root }
  }

  Component {
    id: textMetricsComponent
    Builtins.TextMetrics { renderer: root }
  }

  Component {
    id: animatedImageComponent
    Builtins.AnimatedImage { renderer: root }
  }

  Component {
    id: avatarComponent
    Builtins.Avatar { renderer: root }
  }

  Component {
    id: badgeComponent
    Builtins.Badge { renderer: root }
  }

  Component {
    id: chipComponent
    Builtins.Chip { renderer: root }
  }

  Component {
    id: spacerComponent
    Builtins.Spacer { renderer: root }
  }

  Component {
    id: gridComponent
    Builtins.Grid { renderer: root }
  }

  Component {
    id: rowLayoutComponent
    Builtins.RowLayout { renderer: root }
  }

  Component {
    id: columnLayoutComponent
    Builtins.ColumnLayout { renderer: root }
  }

  Component {
    id: gridLayoutComponent
    Builtins.GridLayout { renderer: root }
  }

  Component {
    id: flowComponent
    Builtins.Flow { renderer: root }
  }

  Component {
    id: centerComponent
    Builtins.Center { renderer: root }
  }

  Component {
    id: cardComponent
    Builtins.Card { renderer: root }
  }

  Component {
    id: aspectRatioComponent
    Builtins.AspectRatio { renderer: root }
  }

  Component {
    id: constrainedBoxComponent
    Builtins.ConstrainedBox { renderer: root }
  }

  Component {
    id: fittedBoxComponent
    Builtins.FittedBox { renderer: root }
  }

  Component {
    id: wrapComponent
    Builtins.Wrap { renderer: root }
  }

  Component {
    id: splitViewComponent
    Builtins.SplitView { renderer: root }
  }

  Component {
    id: stackLayoutComponent
    Builtins.StackLayout { renderer: root }
  }

  Component {
    id: layoutItemProxyComponent
    Builtins.LayoutItemProxy { renderer: root }
  }

  Component {
    id: lazyLoaderComponent
    Builtins.Loader { renderer: root }
  }

  Component {
    id: flickableComponent
    Builtins.Flickable { renderer: root }
  }

  Component {
    id: focusScopeComponent
    Builtins.FocusScope { renderer: root }
  }

  Component {
    id: flipableComponent
    Builtins.Flipable { renderer: root }
  }

  Component {
    id: borderImageComponent
    Builtins.BorderImage { renderer: root }
  }

  Component {
    id: windowComponent
    Builtins.Window { renderer: root }
  }

  Component {
    id: applicationWindowComponent
    Builtins.ApplicationWindow { renderer: root }
  }

  Component {
    id: pageComponent
    Builtins.Page { renderer: root }
  }

  Component {
    id: paneComponent
    Builtins.Pane { renderer: root }
  }

  Component {
    id: frameComponent
    Builtins.Frame { renderer: root }
  }

  Component {
    id: groupBoxComponent
    Builtins.GroupBox { renderer: root }
  }

  Component {
    id: tabsComponent
    Builtins.Tabs { renderer: root }
  }

  Component {
    id: tabBarComponent
    Builtins.TabBar { renderer: root }
  }

  Component {
    id: tabButtonComponent
    Builtins.TabButton { renderer: root }
  }

  Component {
    id: pageIndicatorComponent
    Builtins.PageIndicator { renderer: root }
  }

  Component {
    id: stackViewComponent
    Builtins.StackView { renderer: root }
  }

  Component {
    id: swipeViewComponent
    Builtins.SwipeView { renderer: root }
  }

  Component {
    id: drawerComponent
    Builtins.Drawer { renderer: root }
  }

  Component {
    id: navigationRailComponent
    Builtins.NavigationRail { renderer: root }
  }

  Component {
    id: breadcrumbComponent
    Builtins.Breadcrumb { renderer: root }
  }

  Component {
    id: paginationComponent
    Builtins.Pagination { renderer: root }
  }

  Component {
    id: expansionPanelComponent
    Builtins.ExpansionPanel { renderer: root }
  }

  Component {
    id: accordionComponent
    Builtins.Accordion { renderer: root }
  }

  Component {
    id: toolBarComponent
    Builtins.ToolBar { renderer: root }
  }

  Component {
    id: toolSeparatorComponent
    Builtins.ToolSeparator { renderer: root }
  }

  Component {
    id: menuComponent
    Builtins.Menu { renderer: root }
  }

  Component {
    id: menuItemComponent
    Builtins.MenuItem { renderer: root }
  }

  Component {
    id: menuSeparatorComponent
    Builtins.MenuSeparator { renderer: root }
  }

  Component {
    id: menuBarComponent
    Builtins.MenuBar { renderer: root }
  }

  Component {
    id: contextMenuComponent
    Builtins.ContextMenu { renderer: root }
  }

  Component {
    id: popupComponent
    Builtins.Popup { renderer: root }
  }

  Component {
    id: dialogComponent
    Builtins.Dialog { renderer: root }
  }

  Component {
    id: alertDialogComponent
    Builtins.AlertDialog { renderer: root }
  }

  Component {
    id: messageDialogComponent
    Builtins.MessageDialog { renderer: root }
  }

  Component {
    id: bottomSheetComponent
    Builtins.BottomSheet { renderer: root }
  }

  Component {
    id: modalSheetComponent
    Builtins.ModalSheet { renderer: root }
  }

  Component {
    id: snackbarComponent
    Builtins.Snackbar { renderer: root }
  }

  Component {
    id: bannerComponent
    Builtins.Banner { renderer: root }
  }

  Component {
    id: toastComponent
    Builtins.Toast { renderer: root }
  }

  Component {
    id: busyIndicatorComponent
    Builtins.BusyIndicator { renderer: root }
  }

  Component {
    id: progressRingComponent
    Builtins.ProgressRing { renderer: root }
  }

  Component {
    id: skeletonComponent
    Builtins.Skeleton { renderer: root }
  }

  Component {
    id: itemDelegateComponent
    Builtins.ItemDelegate { renderer: root }
  }

  Component {
    id: checkDelegateComponent
    Builtins.CheckDelegate { renderer: root }
  }

  Component {
    id: radioDelegateComponent
    Builtins.RadioDelegate { renderer: root }
  }

  Component {
    id: switchDelegateComponent
    Builtins.SwitchDelegate { renderer: root }
  }

  Component {
    id: swipeDelegateComponent
    Builtins.SwipeDelegate { renderer: root }
  }

  Component {
    id: gridViewComponent
    Builtins.GridView { renderer: root }
  }

  Component {
    id: tableViewComponent
    Builtins.TableView { renderer: root }
  }

  Component {
    id: treeViewComponent
    Builtins.TreeView { renderer: root }
  }

  Component {
    id: canvasComponent
    Builtins.Canvas { renderer: root }
  }

  Component {
    id: shapeComponent
    Builtins.Shape { renderer: root }
  }

  Component {
    id: lineComponent
    Builtins.Line { renderer: root }
  }

  Component {
    id: pathComponent
    Builtins.Path { renderer: root }
  }

  Component {
    id: circleComponent
    Builtins.Circle { renderer: root }
  }

  Component {
    id: gradientComponent
    Builtins.Gradient { renderer: root }
  }

  Component {
    id: shaderEffectComponent
    Builtins.ShaderEffect { renderer: root }
  }

  Component {
    id: shaderEffectSourceComponent
    Builtins.ShaderEffectSource { renderer: root }
  }

  Component {
    id: multiEffectComponent
    Builtins.MultiEffect { renderer: root }
  }

  Component {
    id: opacityMaskComponent
    Builtins.OpacityMask { renderer: root }
  }

  Component {
    id: blurComponent
    Builtins.Blur { renderer: root }
  }

  Component {
    id: dropShadowComponent
    Builtins.DropShadow { renderer: root }
  }

  Component {
    id: colorizeComponent
    Builtins.Colorize { renderer: root }
  }

  Component {
    id: glowComponent
    Builtins.Glow { renderer: root }
  }

  Component {
    id: particleSystemComponent
    Builtins.ParticleSystem { renderer: root }
  }

  Component {
    id: borderOverlayComponent
    Builtins.BorderOverlay { renderer: root }
  }

  Component {
    id: keyCatcherComponent
    Builtins.KeyCatcher { renderer: root }
  }

  Component {
    id: stackComponent
    Builtins.Stack { renderer: root }
  }

  Component {
    id: scrollComponent
    Builtins.Scroll { renderer: root }
  }

  Component {
    id: rectangleComponent
    Builtins.Rectangle { renderer: root }
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

  Component {
    id: actionButtonComponent
    Builtins.ActionButton { renderer: root }
  }

  Component {
    id: barIconButtonComponent
    Builtins.BarIconButton { renderer: root }
  }

  Component {
    id: barIndicatorComponent
    Builtins.BarIndicator { renderer: root }
  }

  Component {
    id: toggleComponent
    Builtins.Toggle { renderer: root }
  }

  Component {
    id: checkboxComponent
    Builtins.Checkbox { renderer: root }
  }

  Component {
    id: radioButtonComponent
    Builtins.RadioButton { renderer: root }
  }

  Component {
    id: radioGroupComponent
    Builtins.RadioGroup { renderer: root }
  }

  Component {
    id: lineChartComponent
    Builtins.LineChart { renderer: root }
  }

  Component {
    id: areaChartComponent
    Builtins.AreaChart { renderer: root }
  }

  Component {
    id: barChartComponent
    Builtins.BarChart { renderer: root }
  }

  Component {
    id: toggleSwitchComponent
    Builtins.ToggleSwitch { renderer: root }
  }

  Component {
    id: textFieldComponent
    Builtins.TextField { renderer: root }
  }

  Component {
    id: numberFieldComponent
    Builtins.NumberField { renderer: root }
  }

  Component {
    id: textAreaComponent
    Builtins.TextArea { renderer: root }
  }

  Component {
    id: searchFieldComponent
    Builtins.SearchField { renderer: root }
  }

  Component {
    id: passwordFieldComponent
    Builtins.PasswordField { renderer: root }
  }

  Component {
    id: sliderComponent
    Builtins.Slider { renderer: root }
  }

  Component {
    id: rangeSliderComponent
    Builtins.RangeSlider { renderer: root }
  }

  Component {
    id: dialComponent
    Builtins.Dial { renderer: root }
  }

  Component {
    id: spinBoxComponent
    Builtins.SpinBox { renderer: root }
  }

  Component {
    id: doubleSpinBoxComponent
    Builtins.DoubleSpinBox { renderer: root }
  }

  Component {
    id: colorPickerComponent
    Builtins.ColorPicker { renderer: root }
  }

  Component {
    id: datePickerComponent
    Builtins.DatePicker { renderer: root }
  }

  Component {
    id: timePickerComponent
    Builtins.TimePicker { renderer: root }
  }

  Component {
    id: filePickerComponent
    Builtins.FilePicker { renderer: root }
  }

  Component {
    id: folderPickerComponent
    Builtins.FolderPicker { renderer: root }
  }

  Component {
    id: fontPickerComponent
    Builtins.FontPicker { renderer: root }
  }

  Component {
    id: dialogButtonBoxComponent
    Builtins.DialogButtonBox { renderer: root }
  }

  Component {
    id: actionComponent
    Builtins.Action { renderer: root }
  }

  Component {
    id: actionGroupComponent
    Builtins.ActionGroup { renderer: root }
  }

  Component {
    id: dropdownComponent
    Builtins.Dropdown { renderer: root }
  }

  Component {
    id: multiSelectComponent
    Builtins.MultiSelect { renderer: root }
  }

  Component {
    id: buttonGroupComponent
    Builtins.ButtonGroup { renderer: root }
  }

  Component {
    id: progressComponent
    Builtins.Progress { renderer: root }
  }

  Component {
    id: separatorComponent
    Builtins.Separator { renderer: root }
  }
  Component {
    id: dividerComponent
    Builtins.Divider { renderer: root }
  }
  Component {
    id: sectionHeaderComponent
    Builtins.SectionHeader { renderer: root }
  }

  Component {
    id: searchableDropdownComponent
    Builtins.SearchableDropdown { renderer: root }
  }

  Component {
    id: confirmDialogComponent
    Builtins.ConfirmDialog { renderer: root }
  }

  Component {
    id: panelHeroComponent
    Builtins.PanelHero { renderer: root }
  }

  Component {
    id: opticalGlyphComponent
    Builtins.OpticalGlyph { renderer: root }
  }

  Component {
    id: cursorSurfaceComponent
    Builtins.CursorSurface { renderer: root }
  }

  Component {
    id: widgetButtonComponent
    Builtins.WidgetButton { renderer: root }
  }

  Component {
    id: listViewComponent
    Builtins.ListView { renderer: root }
  }
}
