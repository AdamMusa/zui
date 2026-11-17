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

  function labelsPosition(name) {
    var positions = {
      center: AbstractBarSeries.LabelsCenter,
      inside_end: AbstractBarSeries.LabelsInsideEnd,
      inside_base: AbstractBarSeries.LabelsInsideBase,
      outside_end: AbstractBarSeries.LabelsOutsideEnd
    }
    var position = positions[String(name)]
    return position === undefined ? AbstractBarSeries.LabelsCenter : position
  }

  function setLabel(barset) { return barset ? String(barset.label) : "" }

  Component {
    id: seriesComponent
    HorizontalPercentBarSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      useOpenGL: root.renderer.prop("use_open_gl", false) === true
      barWidth: Number(root.renderer.prop("bar_width", 0.5))
      labelsVisible: root.renderer.prop("labels_visible", false) === true
      labelsFormat: String(root.renderer.prop("labels_format", "@value"))
      labelsPosition: root.labelsPosition(root.renderer.prop("labels_position", "center"))
      labelsAngle: Number(root.renderer.prop("labels_angle", 0))
      labelsPrecision: Number(root.renderer.prop("labels_precision", 6))
      onClicked: function(index, barset) { root.send("click", { index: index, set: root.setLabel(barset) }) }
      onDoubleClicked: function(index, barset) { root.send("double_click", { index: index, set: root.setLabel(barset) }) }
      onPressed: function(index, barset) { root.send("press", { index: index, set: root.setLabel(barset) }) }
      onReleased: function(index, barset) { root.send("release", { index: index, set: root.setLabel(barset) }) }
      onHovered: function(status, index, barset) {
        root.send("hover", { index: index, set: root.setLabel(barset), entered: status === true })
      }
      onCountChanged: root.send("change", { count: count })
    }
  }

  // Axis and bar set children render through the normal child delegate; they
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
