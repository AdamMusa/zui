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

  // QtGraphs replaces QtCharts' six bar series types with one series and a
  // barsType property. QtGraphs enforces scoped enums, so each value is named
  // through its enum.
  function barsType(name) {
    var types = {
      groups: BarSeries.BarsType.Groups,
      stacked: BarSeries.BarsType.Stacked,
      stacked_percent: BarSeries.BarsType.StackedPercent
    }
    var type = types[String(name)]
    return type === undefined ? BarSeries.BarsType.Groups : type
  }

  function labelsPosition(name) {
    var positions = {
      center: BarSeries.LabelsPosition.Center,
      inside_end: BarSeries.LabelsPosition.InsideEnd,
      inside_base: BarSeries.LabelsPosition.InsideBase,
      outside_end: BarSeries.LabelsPosition.OutsideEnd
    }
    var position = positions[String(name)]
    return position === undefined ? BarSeries.LabelsPosition.Center : position
  }

  function colorList(key) {
    var colors = renderer.prop(key, [])
    if (!Array.isArray(colors)) return []
    return colors.map(function(color) { return String(color) })
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
    BarSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      selectable: root.renderer.prop("selectable", false) === true
      hoverable: root.renderer.prop("hoverable", false) === true
      valuesMultiplier: Number(root.renderer.prop("values_multiplier", 1))
      barsType: root.barsType(root.renderer.prop("bars_type", "groups"))
      barWidth: Number(root.renderer.prop("bar_width", 0.5))
      labelsVisible: root.renderer.prop("labels_visible", false) === true
      labelsFormat: String(root.renderer.prop("labels_format", ""))
      labelsPosition: root.labelsPosition(root.renderer.prop("labels_position", "center"))
      labelsMargin: Number(root.renderer.prop("labels_margin", 0))
      labelsAngle: Number(root.renderer.prop("labels_angle", 0))
      labelsPrecision: Number(root.renderer.prop("labels_precision", 6))
      seriesColors: root.colorList("series_colors")
      borderColors: root.colorList("border_colors")
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
