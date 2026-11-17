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

  function setLabel(boxset) { return boxset ? String(boxset.label) : "" }

  Component {
    id: seriesComponent
    BoxPlotSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      useOpenGL: root.renderer.prop("use_open_gl", false) === true
      boxOutlineVisible: root.renderer.prop("box_outline_visible", true) !== false
      boxWidth: Number(root.renderer.prop("box_width", 0.5))
      onClicked: function(boxset) { root.send("click", { set: root.setLabel(boxset) }) }
      onDoubleClicked: function(boxset) { root.send("double_click", { set: root.setLabel(boxset) }) }
      onPressed: function(boxset) { root.send("press", { set: root.setLabel(boxset) }) }
      onReleased: function(boxset) { root.send("release", { set: root.setLabel(boxset) }) }
      onHovered: function(status, boxset) {
        root.send("hover", { set: root.setLabel(boxset), entered: status === true })
      }
      onCountChanged: root.send("change", { count: count })
    }
  }

  // Axis and box set children render through the normal child delegate; they
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
  }
  Component.onDestruction: {
    if (root.nativeSeries) root.nativeSeries.destroy()
    root.nativeSeries = null
  }
}
