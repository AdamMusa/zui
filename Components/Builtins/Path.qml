import QtQuick
import QtQuick.Shapes

Shape {
  id: pathRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 120))
  implicitHeight: Number(renderer.prop("height", 120))
  antialiasing: renderer.prop("antialiasing", true) !== false
  asynchronous: renderer.prop("asynchronous", false) === true
  preferredRendererType: String(renderer.prop("preferred_renderer", "geometry")) === "curve" ? Shape.CurveRenderer : Shape.GeometryRenderer
  containsMode: String(renderer.prop("contains_mode", "bounding_rect")) === "fill" ? Shape.FillContains : Shape.BoundingRectContains
  transform: Scale { xScale: Number(renderer.prop("scale", 1)); yScale: Number(renderer.prop("scale", 1)) }

  ShapePath {
    strokeColor: renderer.prop("stroke", renderer.foreground)
    fillColor: renderer.prop("fill", "transparent")
    strokeWidth: Number(renderer.prop("stroke_width", 1))
    capStyle: String(renderer.prop("cap", "square")) === "round" ? ShapePath.RoundCap : (String(renderer.prop("cap", "square")) === "flat" ? ShapePath.FlatCap : ShapePath.SquareCap)
    joinStyle: String(renderer.prop("join", "miter")) === "round" ? ShapePath.RoundJoin : (String(renderer.prop("join", "miter")) === "bevel" ? ShapePath.BevelJoin : ShapePath.MiterJoin)
    fillRule: String(renderer.prop("fill_rule", "winding")) === "odd_even" ? ShapePath.OddEvenFill : ShapePath.WindingFill
    strokeStyle: Array.isArray(renderer.prop("dash_pattern", [])) && renderer.prop("dash_pattern", []).length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
    dashPattern: renderer.prop("dash_pattern", [])
    dashOffset: Number(renderer.prop("dash_offset", 0))
    PathSvg { path: String(renderer.prop("data", "")) }
  }

  onStatusChanged: if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, renderer: rendererType })
  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y, contains: pathRoot.contains(Qt.point(mouse.x, mouse.y)) }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y, contains: pathRoot.contains(Qt.point(mouse.x, mouse.y)) }) }
  }
}
