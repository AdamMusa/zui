import QtQuick
import QtGraphs

// QtGraphs' PieSeries accepts an already built PieSlice, so the slice keeps real
// declarative bindings and is handed to the series once that series exists. QML
// completes children before their parent, so an attach that finds no series yet
// is retried once the current event loop pass has finished building the subtree.
Item {
  id: root
  required property var renderer

  property var nativeSlice: null
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

  // QtGraphs enforces scoped enums, so the value is named through its enum.
  function labelPosition(name) {
    var positions = {
      outside: PieSlice.LabelPosition.Outside,
      inside_horizontal: PieSlice.LabelPosition.InsideHorizontal,
      inside_tangential: PieSlice.LabelPosition.InsideTangential,
      inside_normal: PieSlice.LabelPosition.InsideNormal
    }
    var position = positions[String(name)]
    return position === undefined ? PieSlice.LabelPosition.Outside : position
  }

  function attach() {
    if (root.nativeSlice) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    root.ownerSeries = host.nativeSeries
    root.nativeSlice = sliceComponent.createObject(host.nativeSeries)
    if (root.nativeSlice) root.ownerSeries.append(root.nativeSlice)
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeSlice) return
    renderer.componentError("graph_pie_slice_without_series",
                            "A graph_pie_slice must be declared inside a graph_pie_series", {})
  }

  Component {
    id: sliceComponent
    PieSlice {
      label: String(root.renderer.prop("label", ""))
      value: Number(root.renderer.prop("value", 0))
      labelVisible: root.renderer.prop("label_visible", false) === true
      labelPosition: root.labelPosition(root.renderer.prop("label_position", "outside"))
      labelColor: root.renderer.prop("label_color", root.renderer.foreground)
      labelArmLengthFactor: Number(root.renderer.prop("label_arm_length_factor", 0.15))
      labelFont.family: String(root.renderer.prop("label_font_family", root.renderer.fontFamily))
      labelFont.pixelSize: Number(root.renderer.prop("label_font_size", 11))
      color: root.renderer.prop("color", root.renderer.foreground)
      borderColor: root.renderer.prop("border_color", "transparent")
      borderWidth: Number(root.renderer.prop("border_width", 1))
      exploded: root.renderer.prop("exploded", false) === true
      explodeDistanceFactor: Number(root.renderer.prop("explode_distance_factor", 0.15))
      onPercentageChanged: root.send("change", { percentage: percentage, value: value })
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeSlice) Qt.callLater(root.attachOrReport)
  }
  // The series owns the slice once it is appended, so hand it back rather than
  // destroying it from here.
  Component.onDestruction: {
    if (root.ownerSeries && root.nativeSlice) root.ownerSeries.remove(root.nativeSlice)
    root.nativeSlice = null
    root.ownerSeries = null
  }
}
