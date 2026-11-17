import QtQuick
import QtCharts

// QtCharts series are plain QObjects, not items, and a chart adopts the ones
// that become its children. The adapter therefore stays an invisible item in
// the zui tree and creates the native series inside the chart it finds above
// it, the same self-registration MapCircle performs for Map.
Item {
  id: root
  required property var renderer

  readonly property bool zuiSeriesHost: true
  property var nativeSeries: null
  property string appliedUpperPoints: ""
  property string appliedLowerPoints: ""

  visible: false
  width: 0
  height: 0

  function chartHost() {
    var item = root.parent
    while (item) {
      if (item["zuiChartHost"] === true) return item
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

  // A missing lower boundary is meaningful to QtCharts: the area is filled down
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

  Component {
    id: seriesComponent
    AreaSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      useOpenGL: root.renderer.prop("use_open_gl", false) === true
      color: root.renderer.prop("color", root.renderer.foreground)
      borderColor: root.renderer.prop("border_color", root.renderer.foreground)
      borderWidth: Number(root.renderer.prop("border_width", 2))
      pointLabelsVisible: root.renderer.prop("point_labels_visible", false) === true
      pointLabelsFormat: String(root.renderer.prop("point_labels_format", "@xPoint, @yPoint"))
      pointLabelsColor: root.renderer.prop("point_labels_color", root.renderer.foreground)
      pointLabelsClipping: root.renderer.prop("point_labels_clipping", true) !== false
      pointLabelsFont.family: String(root.renderer.prop("point_labels_font_family", root.renderer.fontFamily))
      pointLabelsFont.pixelSize: Number(root.renderer.prop("point_labels_font_size", 11))
      upperSeries: LineSeries {}
      onClicked: function(point) { root.send("click", { x: point.x, y: point.y }) }
      onDoubleClicked: function(point) { root.send("double_click", { x: point.x, y: point.y }) }
      onPressed: function(point) { root.send("press", { x: point.x, y: point.y }) }
      onReleased: function(point) { root.send("release", { x: point.x, y: point.y }) }
      onHovered: function(point, state) { root.send("hover", { x: point.x, y: point.y, entered: state === true }) }
      onSelected: root.send("select", {})
    }
  }

  // Axis and point children render through the normal child delegate; they
  // find this series by walking up to the zuiSeriesHost marker above.
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  Component.onCompleted: {
    var host = root.chartHost()
    if (!host) {
      renderer.componentError("chart_series_without_chart_view",
                              "A chart series must be declared inside a chart_view or polar_chart_view", {})
      return
    }
    root.nativeSeries = seriesComponent.createObject(host)
    root.applyPoints()
  }
  Component.onDestruction: {
    if (root.nativeSeries) root.nativeSeries.destroy()
    root.nativeSeries = null
  }
  Connections { target: renderer; function onNodeChanged() { root.applyPoints() } }
}
