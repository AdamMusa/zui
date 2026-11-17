import QtQuick
import QtCharts

// QtCharts only exposes append(label, value) to QML, so an already built
// QPieSlice cannot be handed to a series that is created at runtime. The series
// creates the slice and this adapter owns it from then on: appearance is pushed
// on every node revision and the slice's own signals are read back through
// Connections.
Item {
  id: root
  required property var renderer

  property var nativeSlice: null

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

  function labelPosition(name) {
    var positions = {
      outside: PieSlice.LabelOutside,
      inside_horizontal: PieSlice.LabelInsideHorizontal,
      inside_tangential: PieSlice.LabelInsideTangential,
      inside_normal: PieSlice.LabelInsideNormal
    }
    var position = positions[String(name)]
    return position === undefined ? PieSlice.LabelOutside : position
  }

  function apply() {
    var slice = root.nativeSlice
    if (!slice) return
    slice.label = String(renderer.prop("label", ""))
    slice.value = Number(renderer.prop("value", 0))
    slice.labelVisible = renderer.prop("label_visible", false) === true
    slice.labelPosition = root.labelPosition(renderer.prop("label_position", "outside"))
    slice.labelColor = renderer.prop("label_color", renderer.foreground)
    slice.labelArmLengthFactor = Number(renderer.prop("label_arm_length_factor", 0.15))
    slice.labelFont = Qt.font({
      family: String(renderer.prop("label_font_family", renderer.fontFamily)),
      pixelSize: Number(renderer.prop("label_font_size", 11))
    })
    slice.color = renderer.prop("color", renderer.foreground)
    slice.borderColor = renderer.prop("border_color", "transparent")
    slice.borderWidth = Number(renderer.prop("border_width", 1))
    slice.exploded = renderer.prop("exploded", false) === true
    slice.explodeDistanceFactor = Number(renderer.prop("explode_distance_factor", 0.15))
  }

  function attach() {
    if (root.nativeSlice) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    root.nativeSlice = host.nativeSeries.append(String(renderer.prop("label", "")),
                                                Number(renderer.prop("value", 0)))
    root.apply()
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeSlice) return
    renderer.componentError("chart_pie_slice_without_series",
                            "A chart_pie_slice must be declared inside a chart_pie_series", {})
  }

  Connections {
    target: root.nativeSlice
    function onClicked() { root.send("click", { label: root.nativeSlice.label, value: root.nativeSlice.value }) }
    function onDoubleClicked() { root.send("double_click", { label: root.nativeSlice.label, value: root.nativeSlice.value }) }
    function onPressed() { root.send("press", { label: root.nativeSlice.label, value: root.nativeSlice.value }) }
    function onReleased() { root.send("release", { label: root.nativeSlice.label, value: root.nativeSlice.value }) }
    function onHovered(state) { root.send("hover", { label: root.nativeSlice.label, entered: state === true }) }
    function onPercentageChanged() { root.send("change", { percentage: root.nativeSlice.percentage }) }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeSlice) Qt.callLater(root.attachOrReport)
  }
  Connections { target: renderer; function onNodeChanged() { root.apply() } }
}
