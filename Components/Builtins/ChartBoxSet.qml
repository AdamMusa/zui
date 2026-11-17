import QtQuick
import QtCharts

// A box plot series accepts an already built BoxSet (append has a set
// overload, unlike the bar and pie series), so the set keeps real declarative
// bindings and is handed to the series once that series exists. The set is
// parented to the series exactly as a declaratively nested BoxSet would be.
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

  // A box set holds the five-number summary in a fixed order: lower extreme,
  // lower quartile, median, upper quartile, upper extreme.
  function setValues() {
    var values = renderer.prop("values", [])
    if (!Array.isArray(values)) return []
    return values.map(function(value) { return Number(value) })
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
    renderer.componentError("chart_box_set_without_series",
                            "A chart_box_set must be declared inside a chart_box_plot_series", {})
  }

  Component {
    id: setComponent
    BoxSet {
      label: String(root.renderer.prop("label", ""))
      values: root.setValues()
      onClicked: root.send("click", { label: label })
      onDoubleClicked: root.send("double_click", { label: label })
      onPressed: root.send("press", { label: label })
      onReleased: root.send("release", { label: label })
      onHovered: function(status) { root.send("hover", { label: label, entered: status === true }) }
      onValuesChanged: root.send("change", { count: count })
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
