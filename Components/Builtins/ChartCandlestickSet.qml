import QtQuick
import QtCharts

// A candlestick series accepts an already built CandlestickSet, so the set
// keeps real declarative bindings and is handed to the series once that series
// exists. The set is parented to the series exactly as a declaratively nested
// CandlestickSet would be.
Item {
  id: root
  required property var renderer

  property var nativeSet: null
  property var ownerSeries: null

  visible: false
  width: 0
  height: 0

  function seriesHost() {
    var item = root.parent
    while (item) {
      if (item["zuiSeriesHost"] === true) return item
      item = item.parent
    }
    return null
  }

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function attach() {
    if (root.nativeSet) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    root.ownerSeries = host.nativeSeries
    root.nativeSet = setComponent.createObject(host.nativeSeries)
    if (root.nativeSet) root.ownerSeries.append(root.nativeSet)
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeSet) return
    renderer.componentError("chart_candlestick_set_without_series",
                            "A chart_candlestick_set must be declared inside a chart_candlestick_series", {})
  }

  Component {
    id: setComponent
    CandlestickSet {
      // QtCharts keeps the timestamp as milliseconds since the epoch.
      timestamp: Number(root.renderer.prop("timestamp", 0))
      open: Number(root.renderer.prop("open", 0))
      high: Number(root.renderer.prop("high", 0))
      low: Number(root.renderer.prop("low", 0))
      close: Number(root.renderer.prop("close", 0))
      onClicked: root.send("click", { timestamp: timestamp, close: close })
      onDoubleClicked: root.send("double_click", { timestamp: timestamp, close: close })
      onPressed: root.send("press", { timestamp: timestamp, close: close })
      onReleased: root.send("release", { timestamp: timestamp, close: close })
      onHovered: function(status) { root.send("hover", { timestamp: timestamp, entered: status === true }) }
      onCloseChanged: root.send("change", { timestamp: timestamp, close: close })
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeSet) Qt.callLater(root.attachOrReport)
  }
  // The series owns the set once it is appended, so hand it back rather than
  // destroying it from here.
  Component.onDestruction: {
    if (root.ownerSeries && root.nativeSet) root.ownerSeries.remove(root.nativeSet)
    root.nativeSet = null
    root.ownerSeries = null
  }
}
