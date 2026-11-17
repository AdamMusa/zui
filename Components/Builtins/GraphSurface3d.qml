import QtQuick
import QtGraphs

// QtGraphs' GPU surface graph. It takes its series through addSeries() and
// carries the same theme property as the 2D view, so graphs_theme themes it too.
Surface3D {
  id: root
  required property var renderer

  // Graph children locate their host by walking up the visual parent chain.
  readonly property bool zuiGraphsHost: true

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function selectionFlagsFor(name) {
    var modes = {
      none: Graphs3D.SelectionFlag.None,
      item: Graphs3D.SelectionFlag.Item,
      row: Graphs3D.SelectionFlag.Row,
      item_and_row: Graphs3D.SelectionFlag.ItemAndRow,
      column: Graphs3D.SelectionFlag.Column,
      item_and_column: Graphs3D.SelectionFlag.ItemAndColumn,
      row_and_column: Graphs3D.SelectionFlag.RowAndColumn,
      item_row_and_column: Graphs3D.SelectionFlag.ItemRowAndColumn,
      slice: Graphs3D.SelectionFlag.Slice,
      multi_series: Graphs3D.SelectionFlag.MultiSeries
    }
    var requested = renderer.prop(name, "item")
    // selectionMode is a flag set, so an array combines several names.
    if (!Array.isArray(requested)) requested = [requested]
    var flags = 0
    for (var index = 0; index < requested.length; index++) {
      var flag = modes[String(requested[index])]
      if (flag !== undefined) flags |= flag
    }
    return flags === 0 ? Graphs3D.SelectionFlag.Item : flags
  }

  function shadowQualityFor(name) {
    var levels = {
      none: Graphs3D.ShadowQuality.None,
      low: Graphs3D.ShadowQuality.Low,
      medium: Graphs3D.ShadowQuality.Medium,
      high: Graphs3D.ShadowQuality.High,
      soft_low: Graphs3D.ShadowQuality.SoftLow,
      soft_medium: Graphs3D.ShadowQuality.SoftMedium,
      soft_high: Graphs3D.ShadowQuality.SoftHigh
    }
    var level = levels[String(name)]
    return level === undefined ? Graphs3D.ShadowQuality.Medium : level
  }

  function renderingModeFor(name) {
    return String(name) === "direct_to_background"
      ? Graphs3D.RenderingMode.DirectToBackground
      : Graphs3D.RenderingMode.Indirect
  }

  function optimizationHintFor(name) {
    return String(name) === "legacy"
      ? Graphs3D.OptimizationHint.Legacy
      : Graphs3D.OptimizationHint.Default
  }

  function gridLineTypeFor(name) {
    return String(name) === "geometry"
      ? Graphs3D.GridLineType.Geometry
      : Graphs3D.GridLineType.Shader
  }

  function cameraPresetFor(name) {
    var presets = {
      none: Graphs3D.CameraPreset.NoPreset,
      front_low: Graphs3D.CameraPreset.FrontLow,
      front: Graphs3D.CameraPreset.Front,
      front_high: Graphs3D.CameraPreset.FrontHigh,
      left_low: Graphs3D.CameraPreset.LeftLow,
      left: Graphs3D.CameraPreset.Left,
      left_high: Graphs3D.CameraPreset.LeftHigh,
      right_low: Graphs3D.CameraPreset.RightLow,
      right: Graphs3D.CameraPreset.Right,
      right_high: Graphs3D.CameraPreset.RightHigh,
      behind_low: Graphs3D.CameraPreset.BehindLow,
      behind: Graphs3D.CameraPreset.Behind,
      behind_high: Graphs3D.CameraPreset.BehindHigh,
      isometric_left: Graphs3D.CameraPreset.IsometricLeft,
      isometric_left_high: Graphs3D.CameraPreset.IsometricLeftHigh,
      isometric_right: Graphs3D.CameraPreset.IsometricRight,
      isometric_right_high: Graphs3D.CameraPreset.IsometricRightHigh,
      directly_above: Graphs3D.CameraPreset.DirectlyAbove,
      directly_above_cw45: Graphs3D.CameraPreset.DirectlyAboveCW45,
      directly_above_ccw45: Graphs3D.CameraPreset.DirectlyAboveCCW45,
      front_below: Graphs3D.CameraPreset.FrontBelow,
      left_below: Graphs3D.CameraPreset.LeftBelow,
      right_below: Graphs3D.CameraPreset.RightBelow,
      behind_below: Graphs3D.CameraPreset.BehindBelow,
      directly_below: Graphs3D.CameraPreset.DirectlyBelow
    }
    var preset = presets[String(name)]
    return preset === undefined ? Graphs3D.CameraPreset.IsometricLeft : preset
  }

  // A node property carries a vector as [x, y, z] or {x:, y:, z:}.
  function vector3dFor(key, fallback) {
    var value = renderer.prop(key, null)
    if (Array.isArray(value)) return Qt.vector3d(Number(value[0]), Number(value[1]), Number(value[2]))
    if (value !== null && typeof value === "object") {
      return Qt.vector3d(Number(value.x), Number(value.y), Number(value.z))
    }
    return fallback
  }

  function elementNameFor(element) {
    var names = {}
    names[Graphs3D.ElementType.None] = "none"
    names[Graphs3D.ElementType.Series] = "series"
    names[Graphs3D.ElementType.AxisXLabel] = "axis_x_label"
    names[Graphs3D.ElementType.AxisYLabel] = "axis_y_label"
    names[Graphs3D.ElementType.AxisZLabel] = "axis_z_label"
    names[Graphs3D.ElementType.CustomItem] = "custom_item"
    return names[element] || "none"
  }

  implicitWidth: Number(renderer.prop("width", 480))
  implicitHeight: Number(renderer.prop("height", 360))
  visible: renderer.prop("visible", true) !== false
  selectionMode: root.selectionFlagsFor("selection_mode")
  shadowQuality: root.shadowQualityFor(renderer.prop("shadow_quality", "medium"))
  shadowStrength: Number(renderer.prop("shadow_strength", 25))
  msaaSamples: Number(renderer.prop("msaa_samples", 4))
  renderingMode: root.renderingModeFor(renderer.prop("rendering_mode", "indirect"))
  measureFps: renderer.prop("measure_fps", false) === true
  orthoProjection: renderer.prop("ortho_projection", false) === true
  aspectRatio: Number(renderer.prop("aspect_ratio", 2))
  horizontalAspectRatio: Number(renderer.prop("horizontal_aspect_ratio", 0))
  optimizationHint: root.optimizationHintFor(renderer.prop("optimization_hint", "default"))
  polar: renderer.prop("polar", false) === true
  labelMargin: Number(renderer.prop("label_margin", 0.1))
  radialLabelOffset: Number(renderer.prop("radial_label_offset", 1))
  locale: Qt.locale(String(renderer.prop("locale", Qt.locale().name)))
  margin: Number(renderer.prop("margin", -1))
  cameraXRotation: Number(renderer.prop("camera_x_rotation", 0))
  cameraYRotation: Number(renderer.prop("camera_y_rotation", 0))
  cameraZoomLevel: Number(renderer.prop("camera_zoom_level", 100))
  cameraPreset: root.cameraPresetFor(renderer.prop("camera_preset", "isometric_left"))
  cameraTargetPosition: root.vector3dFor("camera_target_position", Qt.vector3d(0, 0, 0))
  minCameraZoomLevel: Number(renderer.prop("min_camera_zoom_level", 10))
  maxCameraZoomLevel: Number(renderer.prop("max_camera_zoom_level", 500))
  wrapCameraXRotation: renderer.prop("wrap_camera_x_rotation", true) !== false
  wrapCameraYRotation: renderer.prop("wrap_camera_y_rotation", false) === true
  rotationEnabled: renderer.prop("rotation_enabled", true) !== false
  zoomAtTargetEnabled: renderer.prop("zoom_at_target_enabled", true) !== false
  selectionEnabled: renderer.prop("selection_enabled", true) !== false
  zoomEnabled: renderer.prop("zoom_enabled", true) !== false
  lightColor: renderer.prop("light_color", "white")
  ambientLightStrength: Number(renderer.prop("ambient_light_strength", 0.25))
  lightStrength: Number(renderer.prop("light_strength", 5))
  gridLineType: root.gridLineTypeFor(renderer.prop("grid_line_type", "shader"))
  flipHorizontalGrid: renderer.prop("flip_horizontal_grid", false) === true

  // A 3D graph's default property is seriesList, which takes only series, so
  // the child delegate is assigned to the item's data list explicitly.
  data: Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  onTapped: function(eventPoint, button) {
    root.send("tap", { x: eventPoint.position.x, y: eventPoint.position.y, button: button })
  }
  onDoubleTapped: function(eventPoint, button) {
    root.send("double_tap", { x: eventPoint.position.x, y: eventPoint.position.y, button: button })
  }
  onLongPressed: root.send("long_press", {})
  onDragged: function(delta) { root.send("drag", { x: delta.x, y: delta.y }) }
  onWheel: function(event) { root.send("wheel", { angle_delta: event.angleDelta.y }) }
  onPinch: function(delta) { root.send("pinch", { delta: delta }) }
  onSelectedElementChanged: root.send("selection_change", { element: root.elementNameFor(root.selectedElement) })
  onCurrentFpsChanged: root.send("fps", { value: root.currentFps })
}
