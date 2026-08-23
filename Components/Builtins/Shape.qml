import QtQuick
import QtQuick.Shapes

Item {
  id: shapeRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 120))
  implicitHeight: Number(renderer.prop("height", 120))

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

  Shape {
    id: nativeShape
    anchors.fill: parent
    antialiasing: renderer.prop("antialiasing", true) !== false
    asynchronous: renderer.prop("asynchronous", false) === true
    preferredRendererType: String(renderer.prop("preferred_renderer", "geometry")) === "curve" ? Shape.CurveRenderer : Shape.GeometryRenderer
    containsMode: String(renderer.prop("contains_mode", "bounding_rect")) === "fill" ? Shape.FillContains : Shape.BoundingRectContains
    transform: Scale { xScale: Number(renderer.prop("scale", 1)); yScale: Number(renderer.prop("scale", 1)) }
    ShapePath {
      strokeColor: renderer.prop("stroke", "transparent")
      fillColor: renderer.prop("fill", "transparent")
      strokeWidth: Number(renderer.prop("stroke_width", 1))
      capStyle: shapeRoot.capStyle()
      joinStyle: shapeRoot.joinStyle()
      fillRule: String(renderer.prop("fill_rule", "winding")) === "odd_even" ? ShapePath.OddEvenFill : ShapePath.WindingFill
      strokeStyle: Array.isArray(renderer.prop("dash_pattern", [])) && renderer.prop("dash_pattern", []).length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
      dashPattern: renderer.prop("dash_pattern", [])
      dashOffset: Number(renderer.prop("dash_offset", 0))
      PathSvg { path: String(renderer.prop("path", "")) }
    }
    onStatusChanged: if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, renderer: rendererType })
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y, contains: nativeShape.contains(Qt.point(mouse.x, mouse.y)) }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y, contains: nativeShape.contains(Qt.point(mouse.x, mouse.y)) }) }
  }
}
