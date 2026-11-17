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
  property string appliedPoints: ""

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

  function penStyle(name) {
    var styles = {
      none: Qt.NoPen, solid: Qt.SolidLine, dash: Qt.DashLine, dot: Qt.DotLine,
      dash_dot: Qt.DashDotLine, dash_dot_dot: Qt.DashDotDotLine
    }
    var style = styles[String(name)]
    return style === undefined ? Qt.SolidLine : style
  }

  function penCapStyle(name) {
    var styles = { flat: Qt.FlatCap, square: Qt.SquareCap, round: Qt.RoundCap }
    var style = styles[String(name)]
    return style === undefined ? Qt.SquareCap : style
  }

  // A points array owns the series data outright. Without one the series is
  // filled by chart_xy_point children, so an absent property must not clear it.
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

  Component {
    id: seriesComponent
    LineSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      useOpenGL: root.renderer.prop("use_open_gl", false) === true
      color: root.renderer.prop("color", root.renderer.foreground)
      selectedColor: root.renderer.prop("selected_color", root.renderer.foreground)
      width: Number(root.renderer.prop("line_width", 2))
      style: root.penStyle(root.renderer.prop("line_style", "solid"))
      capStyle: root.penCapStyle(root.renderer.prop("cap_style", "square"))
      pointsVisible: root.renderer.prop("points_visible", false) === true
      pointLabelsVisible: root.renderer.prop("point_labels_visible", false) === true
      pointLabelsFormat: String(root.renderer.prop("point_labels_format", "@xPoint, @yPoint"))
      pointLabelsColor: root.renderer.prop("point_labels_color", root.renderer.foreground)
      pointLabelsClipping: root.renderer.prop("point_labels_clipping", true) !== false
      pointLabelsFont.family: String(root.renderer.prop("point_labels_font_family", root.renderer.fontFamily))
      pointLabelsFont.pixelSize: Number(root.renderer.prop("point_labels_font_size", 11))
      bestFitLineVisible: root.renderer.prop("best_fit_line_visible", false) === true
      bestFitLineColor: root.renderer.prop("best_fit_line_color", root.renderer.foreground)
      onClicked: function(point) { root.send("click", { x: point.x, y: point.y }) }
      onDoubleClicked: function(point) { root.send("double_click", { x: point.x, y: point.y }) }
      onPressed: function(point) { root.send("press", { x: point.x, y: point.y }) }
      onReleased: function(point) { root.send("release", { x: point.x, y: point.y }) }
      onHovered: function(point, state) { root.send("hover", { x: point.x, y: point.y, entered: state === true }) }
      onCountChanged: root.send("change", { count: count })
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
