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

  function slicePayload(slice) {
    if (!slice) return {}
    return { label: String(slice.label), value: Number(slice.value), percentage: Number(slice.percentage) }
  }

  Component {
    id: seriesComponent
    PieSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      useOpenGL: root.renderer.prop("use_open_gl", false) === true
      horizontalPosition: Number(root.renderer.prop("horizontal_position", 0.5))
      verticalPosition: Number(root.renderer.prop("vertical_position", 0.5))
      size: Number(root.renderer.prop("size", 0.7))
      startAngle: Number(root.renderer.prop("start_angle", 0))
      endAngle: Number(root.renderer.prop("end_angle", 360))
      holeSize: Number(root.renderer.prop("hole_size", 0))
      onClicked: function(slice) { root.send("click", root.slicePayload(slice)) }
      onDoubleClicked: function(slice) { root.send("double_click", root.slicePayload(slice)) }
      onPressed: function(slice) { root.send("press", root.slicePayload(slice)) }
      onReleased: function(slice) { root.send("release", root.slicePayload(slice)) }
      onHovered: function(slice, state) {
        var payload = root.slicePayload(slice)
        payload.entered = state === true
        root.send("hover", payload)
      }
      onCountChanged: root.send("change", { count: count, sum: sum })
    }
  }

  // Slice children render through the normal child delegate; they find this
  // series by walking up to the zuiSeriesHost marker above.
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  Component.onCompleted: {
    var host = root.chartHost()
    if (!host) {
      renderer.componentError("chart_series_without_chart_view",
                              "A chart series must be declared inside a chart_view or polar_chart_view", {})
      return
    }
    root.nativeSeries = seriesComponent.createObject(host)
  }
  Component.onDestruction: {
    if (root.nativeSeries) root.nativeSeries.destroy()
    root.nativeSeries = null
  }
}
