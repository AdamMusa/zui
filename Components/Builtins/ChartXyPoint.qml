import QtQuick

// A single point appended to the XY series above it. The series creates its
// native QtCharts object when its own adapter completes, and QML completes
// children first, so an attach that finds nothing yet is retried once the
// current event loop pass has finished building the subtree.
Item {
  id: root
  required property var renderer

  property bool attached: false

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

  function attach() {
    if (root.attached) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    host.nativeSeries.append(Number(renderer.prop("x", 0)), Number(renderer.prop("y", 0)))
    root.attached = true
  }

  function attachOrReport() {
    root.attach()
    if (root.attached) return
    renderer.componentError("chart_point_without_series",
                            "A chart_xy_point must be declared inside a chart series", {})
  }

  Component.onCompleted: {
    root.attach()
    if (!root.attached) Qt.callLater(root.attachOrReport)
  }
}
