import QtQuick

// QtCharts only exposes append(label, values) to QML, so an already built
// QBarSet cannot be handed to a series that is created at runtime. The series
// creates the set and this adapter owns it from then on: appearance is pushed
// on every node revision and the set's own signals are read back through
// Connections.
Item {
  id: root
  required property var renderer

  property var nativeSet: null
  property string appliedValues: ""

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
    return Array.isArray(values) ? values : []
  }

  function apply() {
    var barset = root.nativeSet
    if (!barset) return
    barset.label = String(renderer.prop("label", ""))
    barset.color = renderer.prop("color", renderer.foreground)
    barset.borderColor = renderer.prop("border_color", "transparent")
    barset.borderWidth = Number(renderer.prop("border_width", 1))
    barset.labelColor = renderer.prop("label_color", renderer.foreground)
    barset.labelFont = Qt.font({
      family: String(renderer.prop("label_font_family", renderer.fontFamily)),
      pixelSize: Number(renderer.prop("label_font_size", 11))
    })
    var values = root.setValues()
    var signature = JSON.stringify(values)
    if (signature === root.appliedValues) return
    root.appliedValues = signature
    barset.values = values
  }

  function attach() {
    if (root.nativeSet) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    root.nativeSet = host.nativeSeries.append(String(renderer.prop("label", "")), root.setValues())
    root.appliedValues = JSON.stringify(root.setValues())
    root.apply()
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeSet) return
    renderer.componentError("chart_bar_set_without_series",
                            "A chart_bar_set must be declared inside a chart bar series", {})
  }

  Connections {
    target: root.nativeSet
    function onClicked(index) { root.send("click", { index: index }) }
    function onDoubleClicked(index) { root.send("double_click", { index: index }) }
    function onPressed(index) { root.send("press", { index: index }) }
    function onReleased(index) { root.send("release", { index: index }) }
    function onHovered(status, index) { root.send("hover", { index: index, entered: status === true }) }
    function onValueChanged(index) { root.send("change", { index: index }) }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeSet) Qt.callLater(root.attachOrReport)
  }
  Connections { target: renderer; function onNodeChanged() { root.apply() } }
}
