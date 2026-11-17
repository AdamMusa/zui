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

  function setPayload(candlestickSet) {
    if (!candlestickSet) return {}
    return {
      timestamp: Number(candlestickSet.timestamp), open: Number(candlestickSet.open),
      high: Number(candlestickSet.high), low: Number(candlestickSet.low),
      close: Number(candlestickSet.close)
    }
  }

  Component {
    id: seriesComponent
    CandlestickSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      opacity: Number(root.renderer.prop("opacity", 1))
      useOpenGL: root.renderer.prop("use_open_gl", false) === true
      maximumColumnWidth: Number(root.renderer.prop("maximum_column_width", -1))
      minimumColumnWidth: Number(root.renderer.prop("minimum_column_width", -1))
      bodyWidth: Number(root.renderer.prop("body_width", 0.5))
      bodyOutlineVisible: root.renderer.prop("body_outline_visible", true) !== false
      capsWidth: Number(root.renderer.prop("caps_width", 0.5))
      capsVisible: root.renderer.prop("caps_visible", false) === true
      increasingColor: root.renderer.prop("increasing_color", "#22c55e")
      decreasingColor: root.renderer.prop("decreasing_color", "#ef4444")
      onClicked: function(candlestickSet) { root.send("click", root.setPayload(candlestickSet)) }
      onDoubleClicked: function(candlestickSet) { root.send("double_click", root.setPayload(candlestickSet)) }
      onPressed: function(candlestickSet) { root.send("press", root.setPayload(candlestickSet)) }
      onReleased: function(candlestickSet) { root.send("release", root.setPayload(candlestickSet)) }
      onHovered: function(status, candlestickSet) {
        var payload = root.setPayload(candlestickSet)
        payload.entered = status === true
        root.send("hover", payload)
      }
      onCountChanged: root.send("change", { count: count })
    }
  }

  // Axis and candlestick set children render through the normal child delegate;
  // they find this series by walking up to the zuiSeriesHost marker above.
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
