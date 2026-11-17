import QtQuick

// A category range is a label plus the value where that category ends. QtCharts
// only exposes append(label, endValue) on CategoryAxis, so the range is handed
// to the axis rather than existing as an object this adapter owns.
Item {
  id: root
  required property var renderer

  property bool attached: false
  property string appliedLabel: ""

  visible: false
  width: 0
  height: 0

  function axisHost() {
    var item = root.parent
    while (item) {
      if (item["zuiAxisHost"] === true) return item
      item = item.parent
    }
    return null
  }

  function attach() {
    if (root.attached) return
    var host = root.axisHost()
    if (!host || !host.nativeAxis) return
    root.appliedLabel = String(renderer.prop("label", ""))
    host.nativeAxis.append(root.appliedLabel, Number(renderer.prop("end_value", 0)))
    root.attached = true
  }

  function attachOrReport() {
    root.attach()
    if (root.attached) return
    renderer.componentError("chart_category_range_without_axis",
                            "A chart_category_range must be declared inside a chart_category_axis", {})
  }

  Component.onCompleted: {
    root.attach()
    if (!root.attached) Qt.callLater(root.attachOrReport)
  }
}
