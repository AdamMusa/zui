import QtQuick

Item {
  id: root
  required property var renderer
  required property var sensor
  required property var fields
  property int handledRefreshRevision: -1
  visible: false

  function publish() {
    if (!sensor || !sensor.reading) return
    var payload = { timestamp: Number(sensor.reading.timestamp) }
    for (var index = 0; index < fields.length; index++) {
      var field = String(fields[index])
      var value = sensor.reading[field]
      if (value !== undefined) payload[field.replace(/([A-Z])/g, "_$1").toLowerCase()] = value
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reading", payload)
  }
  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }
  Binding { target: root.sensor; property: "active"; value: root.renderer.prop("active", false) === true }
  Binding { target: root.sensor; property: "alwaysOn"; value: root.renderer.prop("always_on", false) === true }
  Binding { target: root.sensor; property: "dataRate"; value: Number(root.renderer.prop("data_rate", 0)) }
  Binding { target: root.sensor; property: "skipDuplicates"; value: root.renderer.prop("skip_duplicates", false) === true }
  Binding { target: root.sensor; property: "axesOrientationMode"; value: Number(root.renderer.prop("axes_orientation_mode", 0)) }
  Binding { target: root.sensor; property: "userOrientation"; value: Number(root.renderer.prop("user_orientation", 0)) }
  Connections {
    target: root.sensor
    function onReadingChanged() { root.publish() }
    function onActiveChanged() { root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "active_change", { value: root.sensor.active }) }
    function onBusyChanged() { root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "busy_change", { value: root.sensor.busy }) }
    function onErrorChanged() { if (Number(root.sensor.error) !== 0) root.renderer.componentError("sensor_failed", "The native sensor backend reported an error", { native_code: Number(root.sensor.error) }) }
  }
  Connections { target: root.renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
