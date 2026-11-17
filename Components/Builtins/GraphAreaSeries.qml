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
  property string appliedUpperPoints: ""
  property string appliedLowerPoints: ""

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

  function fillSeries(series, key) {
    var raw = renderer.prop(key, [])
    if (!Array.isArray(raw)) raw = []
    series.clear()
    for (var index = 0; index < raw.length; index++) {
      var point = raw[index]
      if (Array.isArray(point)) series.append(Number(point[0]), Number(point[1]))
      else if (point !== null && typeof point === "object") series.append(Number(point.x), Number(point.y))
      else series.append(index, Number(point))
    }
    return JSON.stringify(raw)
  }

  // A missing lower boundary is meaningful to QtGraphs: the area is filled down
  // to the axis instead of to a second line, so the series is only created when
  // the application actually asked for one.
  function applyPoints() {
    if (!root.nativeSeries) return
    var upper = JSON.stringify(renderer.prop("upper_points", []))
    if (upper !== root.appliedUpperPoints) {
      root.appliedUpperPoints = root.fillSeries(root.nativeSeries.upperSeries, "upper_points")
    }
    if (!renderer.hasProp("lower_points")) return

    var lower = JSON.stringify(renderer.prop("lower_points", []))
    if (lower === root.appliedLowerPoints) return
    if (!root.nativeSeries.lowerSeries) {
      root.nativeSeries.lowerSeries = boundaryComponent.createObject(root.nativeSeries)
    }
    root.appliedLowerPoints = root.fillSeries(root.nativeSeries.lowerSeries, "lower_points")
  }

  Component { id: boundaryComponent; LineSeries {} }

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
    AreaSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      selectable: root.renderer.prop("selectable", false) === true
      hoverable: root.renderer.prop("hoverable", false) === true
      valuesMultiplier: Number(root.renderer.prop("values_multiplier", 1))
      color: root.renderer.prop("color", root.renderer.foreground)
      selectedColor: root.renderer.prop("selected_color", root.renderer.foreground)
      borderColor: root.renderer.prop("border_color", root.renderer.foreground)
      selectedBorderColor: root.renderer.prop("selected_border_color", root.renderer.foreground)
      borderWidth: Number(root.renderer.prop("border_width", 2))
      selected: root.renderer.prop("selected", false) === true
      upperSeries: LineSeries {}
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
      onSelectedChanged: root.send("select", { selected: selected })
    }
  }

  Component.onCompleted: {
    root.attach()
    root.applyPoints()
  }
  // The graph owns the series after addSeries, so hand it back rather than
  // destroying it from here.
  Component.onDestruction: {
    if (root.ownerGraph && root.nativeSeries) root.ownerGraph.removeSeries(root.nativeSeries)
    root.nativeSeries = null
    root.ownerGraph = null
  }
  Connections { target: renderer; function onNodeChanged() { root.applyPoints() } }
}
