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
  property string appliedPoints: ""

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

  // A points array owns the series data outright. Without one the series is
  // filled by graph_xy_point children, so an absent property must not clear it.
  function applyPoints() {
    if (!root.nativeSeries || !renderer.hasProp("points")) return
    var raw = renderer.prop("points", [])
    if (!Array.isArray(raw)) raw = []
    var signature = JSON.stringify(raw)
    if (signature === root.appliedPoints) return
    root.appliedPoints = signature
    root.nativeSeries.clear()
    for (var index = 0; index < raw.length; index++) {
      var point = raw[index]
      if (Array.isArray(point)) root.nativeSeries.append(Number(point[0]), Number(point[1]))
      else if (point !== null && typeof point === "object") root.nativeSeries.append(Number(point.x), Number(point.y))
      else root.nativeSeries.append(index, Number(point))
    }
  }

  function penCapStyle(name) {
    var styles = { flat: Qt.FlatCap, square: Qt.SquareCap, round: Qt.RoundCap }
    var style = styles[String(name)]
    return style === undefined ? Qt.SquareCap : style
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
    LineSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      selectable: root.renderer.prop("selectable", false) === true
      hoverable: root.renderer.prop("hoverable", false) === true
      valuesMultiplier: Number(root.renderer.prop("values_multiplier", 1))
      color: root.renderer.prop("color", root.renderer.foreground)
      selectedColor: root.renderer.prop("selected_color", root.renderer.foreground)
      draggable: root.renderer.prop("draggable", false) === true
      width: Number(root.renderer.prop("line_width", 2))
      capStyle: root.penCapStyle(root.renderer.prop("cap_style", "square"))
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
      onCountChanged: root.send("change", { count: count })
      onSelectedPointsChanged: root.send("select", {})
    }
  }

  // Point, set and slice children render through the normal child delegate; they
  // find this series by walking up to the zuiSeriesHost marker above.
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

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
