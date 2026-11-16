import QtQuick
import QtQuick.Shapes
import "Support" as Support

Shape {
  id: pathRoot
  required property var renderer
  property var createdElements: []
  property string appliedElementKey: ""
  implicitWidth: Number(renderer.prop("width", 120))
  implicitHeight: Number(renderer.prop("height", 120))
  antialiasing: renderer.prop("antialiasing", true) !== false
  asynchronous: renderer.prop("asynchronous", false) === true
  preferredRendererType: String(renderer.prop("preferred_renderer", "geometry")) === "curve" ? Shape.CurveRenderer : Shape.GeometryRenderer
  containsMode: String(renderer.prop("contains_mode", "bounding_rect")) === "fill" ? Shape.FillContains : Shape.BoundingRectContains
  transform: Scale { xScale: Number(renderer.prop("scale", 1)); yScale: Number(renderer.prop("scale", 1)) }

  function requestedSegments() {
    var segments = renderer.prop("segments", null)
    return Array.isArray(segments) && segments.length > 0 ? segments : null
  }

  function rebuildElements() {
    var segments = requestedSegments()
    var key = JSON.stringify({ segments: segments, data: String(renderer.prop("data", "")) })
    if (key === appliedElementKey) return
    appliedElementKey = key
    nativePath.pathElements = []
    for (var index = 0; index < createdElements.length; index++) createdElements[index].destroy()
    if (!segments) {
      createdElements = [svgFactory.createObject(pathRoot, { path: String(renderer.prop("data", "")) })]
      nativePath.pathElements = createdElements
      return
    }
    var built = segmentFactory.build(pathRoot, segments)
    createdElements = built.elements
    nativePath.pathElements = createdElements
    if (built.rejected.length > 0)
      renderer.componentError("path_segment_rejected",
        "path accepts only the Qt path element types", { types: built.rejected })
  }

  Component { id: svgFactory; PathSvg {} }
  Support.PathSegmentFactory { id: segmentFactory }

  ShapePath {
    id: nativePath
    strokeColor: renderer.prop("stroke", renderer.foreground)
    fillColor: renderer.prop("fill", "transparent")
    strokeWidth: Number(renderer.prop("stroke_width", 1))
    startX: Number(renderer.prop("start_x", 0))
    startY: Number(renderer.prop("start_y", 0))
    capStyle: String(renderer.prop("cap", "square")) === "round" ? ShapePath.RoundCap : (String(renderer.prop("cap", "square")) === "flat" ? ShapePath.FlatCap : ShapePath.SquareCap)
    joinStyle: String(renderer.prop("join", "miter")) === "round" ? ShapePath.RoundJoin : (String(renderer.prop("join", "miter")) === "bevel" ? ShapePath.BevelJoin : ShapePath.MiterJoin)
    fillRule: String(renderer.prop("fill_rule", "winding")) === "odd_even" ? ShapePath.OddEvenFill : ShapePath.WindingFill
    strokeStyle: Array.isArray(renderer.prop("dash_pattern", [])) && renderer.prop("dash_pattern", []).length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
    dashPattern: renderer.prop("dash_pattern", [])
    dashOffset: Number(renderer.prop("dash_offset", 0))
  }

  onStatusChanged: if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, renderer: rendererType })
  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y, contains: pathRoot.contains(Qt.point(mouse.x, mouse.y)) }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y, contains: pathRoot.contains(Qt.point(mouse.x, mouse.y)) }) }
  }

  Component.onCompleted: rebuildElements()
  Connections { target: renderer; function onNodeChanged() { pathRoot.rebuildElements() } }
}
