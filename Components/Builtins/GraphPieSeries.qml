import QtQuick
import QtGraphs

// QtGraphs graphs accept a series through addSeries(), so the adapter builds the
// native series with real bindings and hands it over to the graph it finds above
// it, then takes it back on destruction.
Item {
  id: root
  required property var renderer

  readonly property bool zuiSeriesHost: true
  property var nativeSeries: null
  property var ownerGraph: null

  visible: false
  width: 0
  height: 0

  function graphsHost() {
    var item = root.parent
    while (item) {
      if (item["zuiGraphsHost"] === true) return item
      item = item.parent
    }
    return null
  }

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function attach() {
    if (root.nativeSeries) return
    var host = root.graphsHost()
    if (!host) {
      renderer.componentError("graph_series_without_graph",
                              "A graph series must be declared inside a graphs_view", {})
      return
    }
    root.ownerGraph = host
    root.nativeSeries = seriesComponent.createObject(host)
    if (root.nativeSeries) host.addSeries(root.nativeSeries)
  }

  Component {
    id: seriesComponent
    PieSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      selectable: root.renderer.prop("selectable", false) === true
      hoverable: root.renderer.prop("hoverable", false) === true
      valuesMultiplier: Number(root.renderer.prop("values_multiplier", 1))
      horizontalPosition: Number(root.renderer.prop("horizontal_position", 0.5))
      verticalPosition: Number(root.renderer.prop("vertical_position", 0.5))
      pieSize: Number(root.renderer.prop("pie_size", 0.7))
      startAngle: Number(root.renderer.prop("start_angle", 0))
      endAngle: Number(root.renderer.prop("end_angle", 360))
      holeSize: Number(root.renderer.prop("hole_size", 0))
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
      onCountChanged: root.send("change", { count: count, sum: sum })
    }
  }

  // Point, set and slice children render through the normal child delegate; they
  // find this series by walking up to the zuiSeriesHost marker above.
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  Component.onCompleted: {
    root.attach()
  }
  // The graph owns the series after addSeries, so hand it back rather than
  // destroying it from here.
  Component.onDestruction: {
    if (root.ownerGraph && root.nativeSeries) root.ownerGraph.removeSeries(root.nativeSeries)
    root.nativeSeries = null
    root.ownerGraph = null
  }
}
