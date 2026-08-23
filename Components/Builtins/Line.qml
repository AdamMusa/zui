import QtQuick
import QtQuick.Shapes

Shape {
  id: lineRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", Math.max(Number(renderer.prop("x1", 0)), Number(renderer.prop("x2", 100))) + Number(renderer.prop("stroke_width", 1))))
  implicitHeight: Number(renderer.prop("height", Math.max(Number(renderer.prop("y1", 0)), Number(renderer.prop("y2", 0))) + Number(renderer.prop("stroke_width", 1))))
  antialiasing: renderer.prop("antialiasing", true) !== false
  ShapePath {
    strokeColor: renderer.prop("stroke", renderer.foreground)
    fillColor: "transparent"
    strokeWidth: Number(renderer.prop("stroke_width", 1))
    capStyle: String(renderer.prop("cap", "round")) === "flat" ? ShapePath.FlatCap : (String(renderer.prop("cap", "round")) === "square" ? ShapePath.SquareCap : ShapePath.RoundCap)
    strokeStyle: Array.isArray(renderer.prop("dash_pattern", [])) && renderer.prop("dash_pattern", []).length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
    dashPattern: renderer.prop("dash_pattern", [])
    dashOffset: Number(renderer.prop("dash_offset", 0))
    startX: Number(renderer.prop("x1", 0))
    startY: Number(renderer.prop("y1", 0))
    PathLine { x: Number(renderer.prop("x2", 100)); y: Number(renderer.prop("y2", 0)) }
  }
  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y }) }
  }
}
