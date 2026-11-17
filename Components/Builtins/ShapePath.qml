import QtQuick
import QtQuick.Shapes

Item {
  id: pathRoot
  required property var renderer
  property var createdStops: []
  implicitWidth: Number(renderer.prop("width", 120))
  implicitHeight: Number(renderer.prop("height", 120))

  readonly property string gradientType: String(renderer.prop("gradient", "none"))

  function capStyle() {
    var cap = String(renderer.prop("cap", "square"))
    if (cap === "round") return ShapePath.RoundCap
    if (cap === "flat") return ShapePath.FlatCap
    return ShapePath.SquareCap
  }

  function joinStyle() {
    var join = String(renderer.prop("join", "miter"))
    if (join === "round") return ShapePath.RoundJoin
    if (join === "bevel") return ShapePath.BevelJoin
    return ShapePath.MiterJoin
  }

  function strokeStyle() {
    var requested = renderer.prop("stroke_style", "")
    var pattern = renderer.prop("dash_pattern", [])
    if (String(requested) === "") return Array.isArray(pattern) && pattern.length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
    return String(requested) === "dash" ? ShapePath.DashLine : ShapePath.SolidLine
  }

  function spreadMode() {
    var spread = String(renderer.prop("spread", "pad"))
    if (spread === "reflect") return ShapeGradient.ReflectSpread
    if (spread === "repeat") return ShapeGradient.RepeatSpread
    return ShapeGradient.PadSpread
  }

  function pathHints() {
    var hints = renderer.prop("path_hints", [])
    if (!Array.isArray(hints)) return 0
    var known = {
      linear: ShapePath.PathLinear, quadratic: ShapePath.PathQuadratic, convex: ShapePath.PathConvex,
      fill_on_right: ShapePath.PathFillOnRight, solid: ShapePath.PathSolid,
      non_intersecting: ShapePath.PathNonIntersecting,
      non_overlapping_control_point_triangles: ShapePath.PathNonOverlappingControlPointTriangles
    }
    var flags = 0
    for (var index = 0; index < hints.length; index++) {
      var hint = known[String(hints[index])]
      if (hint === undefined) renderer.componentError("path_hint_unsupported", "Unknown path hint: " + hints[index], { path_hint: String(hints[index]) })
      else flags |= hint
    }
    return flags
  }

  function fillTransform() {
    var values = renderer.prop("fill_transform", [])
    if (!Array.isArray(values) || values.length !== 16) return Qt.matrix4x4()
    return Qt.matrix4x4(Number(values[0]), Number(values[1]), Number(values[2]), Number(values[3]),
                        Number(values[4]), Number(values[5]), Number(values[6]), Number(values[7]),
                        Number(values[8]), Number(values[9]), Number(values[10]), Number(values[11]),
                        Number(values[12]), Number(values[13]), Number(values[14]), Number(values[15]))
  }

  function fillItemTarget() {
    var target = String(renderer.prop("fill_item", ""))
    if (target === "") return null
    var resolved = renderer.findRenderedItem(target)
    if (!resolved) renderer.componentError("fill_item_missing", "No rendered item with id " + target, { fill_item: target })
    return resolved
  }

  function activeGradient() {
    if (pathRoot.gradientType === "linear") return linearFill
    if (pathRoot.gradientType === "radial") return radialFill
    if (pathRoot.gradientType === "conical") return conicalFill
    return null
  }

  function stopPosition(index, count) {
    var stops = renderer.prop("stops", [])
    return Array.isArray(stops) && index < stops.length ? Number(stops[index]) : (count <= 1 ? 0 : index / (count - 1))
  }

  function rebuildStops() {
    for (var oldIndex = 0; oldIndex < createdStops.length; oldIndex++) createdStops[oldIndex].destroy()
    var colors = renderer.prop("colors", [])
    var replacements = []
    if (Array.isArray(colors)) {
      for (var index = 0; index < colors.length; index++) {
        replacements.push(stopFactory.createObject(pathRoot, {
          position: stopPosition(index, colors.length), color: String(colors[index])
        }))
      }
    }
    createdStops = replacements
  }

  Component { id: stopFactory; GradientStop {} }
  Connections { target: renderer; function onNodeChanged() { pathRoot.rebuildStops() } }
  Component.onCompleted: rebuildStops()

  LinearGradient {
    id: linearFill
    x1: Number(renderer.prop("start_x", 0)); y1: Number(renderer.prop("start_y", 0))
    x2: Number(renderer.prop("end_x", pathRoot.width)); y2: Number(renderer.prop("end_y", 0))
    spread: pathRoot.spreadMode()
    stops: pathRoot.gradientType === "linear" ? pathRoot.createdStops : []
  }

  RadialGradient {
    id: radialFill
    centerX: Number(renderer.prop("center_x", pathRoot.width / 2)); centerY: Number(renderer.prop("center_y", pathRoot.height / 2))
    centerRadius: Number(renderer.prop("center_radius", Math.max(pathRoot.width, pathRoot.height) / 2))
    focalX: Number(renderer.prop("focal_x", centerX)); focalY: Number(renderer.prop("focal_y", centerY))
    focalRadius: Number(renderer.prop("focal_radius", 0))
    spread: pathRoot.spreadMode()
    stops: pathRoot.gradientType === "radial" ? pathRoot.createdStops : []
  }

  ConicalGradient {
    id: conicalFill
    centerX: Number(renderer.prop("center_x", pathRoot.width / 2)); centerY: Number(renderer.prop("center_y", pathRoot.height / 2))
    angle: Number(renderer.prop("angle", 0))
    stops: pathRoot.gradientType === "conical" ? pathRoot.createdStops : []
  }

  Shape {
    id: nativeShape
    anchors.fill: parent
    antialiasing: renderer.prop("antialiasing", true) !== false
    asynchronous: renderer.prop("asynchronous", false) === true
    vendorExtensionsEnabled: renderer.prop("vendor_extensions", false) === true
    preferredRendererType: String(renderer.prop("preferred_renderer", "geometry")) === "curve" ? Shape.CurveRenderer : Shape.GeometryRenderer
    containsMode: String(renderer.prop("contains_mode", "bounding_rect")) === "fill" ? Shape.FillContains : Shape.BoundingRectContains
    fillMode: {
      var mode = String(renderer.prop("fill_mode", "no_resize"))
      if (mode === "preserve_aspect_fit") return Shape.PreserveAspectFit
      if (mode === "preserve_aspect_crop") return Shape.PreserveAspectCrop
      if (mode === "stretch") return Shape.Stretch
      return Shape.NoResize
    }
    horizontalAlignment: {
      var alignment = String(renderer.prop("horizontal_alignment", "left"))
      if (alignment === "right") return Shape.AlignRight
      if (alignment === "center") return Shape.AlignHCenter
      return Shape.AlignLeft
    }
    verticalAlignment: {
      var alignment = String(renderer.prop("vertical_alignment", "top"))
      if (alignment === "bottom") return Shape.AlignBottom
      if (alignment === "center") return Shape.AlignVCenter
      return Shape.AlignTop
    }

    ShapePath {
      strokeColor: renderer.prop("stroke", "transparent")
      fillColor: renderer.prop("fill", "transparent")
      strokeWidth: Number(renderer.prop("stroke_width", 1))
      capStyle: pathRoot.capStyle()
      joinStyle: pathRoot.joinStyle()
      miterLimit: Math.max(0, Math.round(Number(renderer.prop("miter_limit", 2))))
      fillRule: String(renderer.prop("fill_rule", "winding")) === "odd_even" ? ShapePath.OddEvenFill : ShapePath.WindingFill
      strokeStyle: pathRoot.strokeStyle()
      dashPattern: renderer.prop("dash_pattern", [])
      dashOffset: Number(renderer.prop("dash_offset", 0))
      scale: Qt.size(Number(renderer.prop("path_scale_x", 1)), Number(renderer.prop("path_scale_y", 1)))
      pathHints: pathRoot.pathHints()
      fillTransform: pathRoot.fillTransform()
      fillItem: pathRoot.fillItemTarget()
      fillGradient: pathRoot.activeGradient()
      PathSvg { path: String(renderer.prop("path", "")) }
    }

    onStatusChanged: if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, renderer: rendererType, bounding_rect: { x: boundingRect.x, y: boundingRect.y, width: boundingRect.width, height: boundingRect.height } })
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y, contains: nativeShape.contains(Qt.point(mouse.x, mouse.y)) }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y, contains: nativeShape.contains(Qt.point(mouse.x, mouse.y)) }) }
  }
}
