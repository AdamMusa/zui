import QtQuick

Item {
  id: root
  required property var renderer
  required property var sensor
  required property var fields
  property var metadataFields: []
  property int handledRefreshRevision: -1
  property int handledCommandRevision: -1
  visible: false

  function snakeCase(name) { return String(name).replace(/([A-Z])/g, "_$1").toLowerCase() }

  function rangeList(ranges) {
    var values = []
    if (!ranges) return values
    for (var index = 0; index < ranges.length; index++) {
      var range = ranges[index]
      if (!range) continue
      values.push({ minimum: Number(range.minimum), maximum: Number(range.maximum) })
    }
    return values
  }

  function outputRangeList(ranges) {
    var values = []
    if (!ranges) return values
    for (var index = 0; index < ranges.length; index++) {
      var range = ranges[index]
      if (!range) continue
      values.push({ minimum: Number(range.minimum), maximum: Number(range.maximum), accuracy: Number(range.accuracy) })
    }
    return values
  }

  function readingPayload() {
    if (!sensor || !sensor.reading) return null
    var payload = { timestamp: Number(sensor.reading.timestamp) }
    for (var index = 0; index < fields.length; index++) {
      var field = String(fields[index])
      var value = sensor.reading[field]
      if (value !== undefined) payload[snakeCase(field)] = value
    }
    return payload
  }

  function publish() {
    var payload = readingPayload()
    if (!payload) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reading", payload)
  }

  function publishMetadata() {
    if (!sensor) return
    var payload = {
      identifier: String(sensor.identifier),
      type: String(sensor.type),
      description: String(sensor.description),
      connected: sensor.connectedToBackend === true,
      busy: sensor.busy === true,
      active: sensor.active === true,
      data_rate: Number(sensor.dataRate),
      output_range: Number(sensor.outputRange),
      buffer_size: Number(sensor.bufferSize),
      max_buffer_size: Number(sensor.maxBufferSize),
      efficient_buffer_size: Number(sensor.efficientBufferSize),
      current_orientation: Number(sensor.currentOrientation),
      available_data_rates: rangeList(sensor.availableDataRates),
      output_ranges: outputRangeList(sensor.outputRanges)
    }
    for (var index = 0; index < metadataFields.length; index++) {
      var field = String(metadataFields[index])
      var value = sensor[field]
      if (value !== undefined) payload[snakeCase(field)] = value
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "metadata", payload)
  }

  function runCommand() {
    var revision = Number(root.renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    handledCommandRevision = revision
    var command = String(root.renderer.prop("command", ""))
    if (command === "") return
    if (command === "start") { sensor.start(); return }
    if (command === "stop") { sensor.stop(); return }
    if (command === "update") { sensor.updateReading(); return }
    if (command === "calibrate" && sensor.calibrate !== undefined) { sensor.calibrate(); return }
    root.renderer.componentError("sensor_command_rejected", "The sensor does not support the requested command", { command: command })
  }

  function refresh() {
    runCommand()
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
    publishMetadata()
  }
  Binding { target: root.sensor; property: "active"; value: root.renderer.prop("active", false) === true }
  Binding { target: root.sensor; property: "alwaysOn"; value: root.renderer.prop("always_on", false) === true }
  Binding { target: root.sensor; property: "dataRate"; value: Number(root.renderer.prop("data_rate", 0)) }
  Binding { target: root.sensor; property: "skipDuplicates"; value: root.renderer.prop("skip_duplicates", false) === true }
  Binding { target: root.sensor; property: "axesOrientationMode"; value: Number(root.renderer.prop("axes_orientation_mode", 0)) }
  Binding { target: root.sensor; property: "userOrientation"; value: Number(root.renderer.prop("user_orientation", 0)) }
  Binding {
    target: root.sensor
    property: "outputRange"
    value: Number(root.renderer.prop("output_range", -1))
    when: Number(root.renderer.prop("output_range", -1)) >= 0
  }
  Binding { target: root.sensor; property: "bufferSize"; value: Number(root.renderer.prop("buffer_size", 1)) }
  Binding {
    target: root.sensor
    property: "identifier"
    value: root.renderer.prop("identifier", "")
    when: String(root.renderer.prop("identifier", "")) !== ""
  }
  Connections {
    target: root.sensor
    function onReadingChanged() { root.publish() }
    function onActiveChanged() { root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "active_change", { value: root.sensor.active }) }
    function onBusyChanged() { root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "busy_change", { value: root.sensor.busy }) }
    function onConnectedToBackendChanged() { root.publishMetadata() }
    function onAvailableDataRatesChanged() { root.publishMetadata() }
    function onOutputRangesChanged() { root.publishMetadata() }
    function onDescriptionChanged() { root.publishMetadata() }
    function onErrorChanged() { if (Number(root.sensor.error) !== 0) root.renderer.componentError("sensor_failed", "The native sensor backend reported an error", { native_code: Number(root.sensor.error) }) }
  }
  Connections { target: root.renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
