import QtQuick
import QtGraphs

// QtGraphs' BarSeries accepts an already built BarSet, so the set keeps real
// declarative bindings and is handed to the series once that series exists. QML
// completes children before their parent, so an attach that finds no series yet
// is retried once the current event loop pass has finished building the subtree.
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
    renderer.componentError("graph_bar_set_without_series",
                            "A graph_bar_set must be declared inside a graph_bar_series", {})
  }

  Component {
    id: setComponent
    BarSet {
      label: String(root.renderer.prop("label", ""))
      values: root.setValues()
      color: root.renderer.prop("color", root.renderer.foreground)
      selectedColor: root.renderer.prop("selected_color", root.renderer.foreground)
      borderColor: root.renderer.prop("border_color", "transparent")
      borderWidth: Number(root.renderer.prop("border_width", 1))
      labelColor: root.renderer.prop("label_color", root.renderer.foreground)
      onValuesChanged: root.send("change", { count: count })
      onSelectedBarsChanged: root.send("select", {})
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
