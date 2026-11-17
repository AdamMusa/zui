import QtQuick
import QtGraphs

// QtGraphs' 2D graph surface. Unlike QtCharts it exposes addSeries() to QML, so
// series children hand themselves over instead of relying on object parenting,
// and the axes belong to the view rather than to each series.
GraphsView {
  id: root
  required property var renderer

  // Graph children locate their host by walking up the visual parent chain.
  readonly property bool zuiGraphsHost: true

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function graphOrientation(name) {
    return String(name) === "vertical" ? Qt.Vertical : Qt.Horizontal
  }

  implicitWidth: Number(renderer.prop("width", 480))
  implicitHeight: Number(renderer.prop("height", 320))
  visible: renderer.prop("visible", true) !== false
  antialiasing: renderer.prop("antialiasing", true) !== false
  orientation: root.graphOrientation(renderer.prop("orientation", "horizontal"))
  marginTop: Number(renderer.prop("margin_top", 20))
  marginBottom: Number(renderer.prop("margin_bottom", 20))
  marginLeft: Number(renderer.prop("margin_left", 20))
  marginRight: Number(renderer.prop("margin_right", 20))
  axisXSmoothing: Number(renderer.prop("axis_x_smoothing", 1))
  axisYSmoothing: Number(renderer.prop("axis_y_smoothing", 1))
  gridSmoothing: Number(renderer.prop("grid_smoothing", 1))
  shadowVisible: renderer.prop("shadow_visible", false) === true
  shadowColor: renderer.prop("shadow_color", "#40000000")
  shadowBarWidth: Number(renderer.prop("shadow_bar_width", 2))
  shadowXOffset: Number(renderer.prop("shadow_x_offset", 0))
  shadowYOffset: Number(renderer.prop("shadow_y_offset", 0))
  shadowSmoothing: Number(renderer.prop("shadow_smoothing", 4))

  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  onHoverEnter: function(seriesName, position, value) {
    root.send("hover_enter", { series: String(seriesName), x: position.x, y: position.y,
                               value_x: value.x, value_y: value.y })
  }
  onHoverExit: function(seriesName, position) {
    root.send("hover_exit", { series: String(seriesName), x: position.x, y: position.y })
  }
  onHover: function(seriesName, position, value) {
    root.send("hover", { series: String(seriesName), x: position.x, y: position.y,
                         value_x: value.x, value_y: value.y })
  }
}
