import QtQuick
import QtQuick.Shapes

Shape {
  id: circleRoot
  required property var renderer
  readonly property real circleRadius: Number(renderer.prop("radius", 50))
  implicitWidth: Number(renderer.prop("width", circleRadius * 2 + Number(renderer.prop("stroke_width", 1))))
  implicitHeight: Number(renderer.prop("height", circleRadius * 2 + Number(renderer.prop("stroke_width", 1))))
  antialiasing: renderer.prop("antialiasing", true) !== false
  ShapePath {
    strokeColor: renderer.prop("stroke", renderer.foreground)
    fillColor: renderer.prop("fill", "transparent")
    strokeWidth: Number(renderer.prop("stroke_width", 1))
    capStyle: String(renderer.prop("cap", "round")) === "flat" ? ShapePath.FlatCap : (String(renderer.prop("cap", "round")) === "square" ? ShapePath.SquareCap : ShapePath.RoundCap)
    strokeStyle: Array.isArray(renderer.prop("dash_pattern", [])) && renderer.prop("dash_pattern", []).length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
    dashPattern: renderer.prop("dash_pattern", [])
    dashOffset: Number(renderer.prop("dash_offset", 0))
    PathAngleArc {
      centerX: Number(renderer.prop("center_x", circleRoot.width / 2))
      centerY: Number(renderer.prop("center_y", circleRoot.height / 2))
      radiusX: circleRoot.circleRadius
      radiusY: circleRoot.circleRadius
      startAngle: Number(renderer.prop("start_angle", 0))
      sweepAngle: Number(renderer.prop("sweep_angle", 360))
      moveToStart: true
    }
  }
  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y }) }
  }
}
