import QtQuick
import QtPositioning

Item {
  id: root
  required property var renderer
  property int handledRefreshRevision: -1
  property int handledCommandRevision: -1
  visible: false
  function preferredMethods() {
    var value = String(renderer.prop("preferred_methods", "all"))
    if (value === "satellite") return PositionSource.SatellitePositioningMethods
    if (value === "non_satellite") return PositionSource.NonSatellitePositioningMethods
    return PositionSource.AllPositioningMethods
  }
  function coordinatePayload(coordinate) {
    return { latitude: coordinate.latitude, longitude: coordinate.longitude,
      altitude: coordinate.altitude, valid: coordinate.isValid }
  }
  function timestampPayload(timestamp) {
    return timestamp && !isNaN(timestamp.getTime()) ? timestamp.toISOString() : ""
  }
  // PositionSource.parameters is a read-only default-property list that the backend consumes
  // while it is being created, before zui can push dynamic properties into it. Qt's
  // post-construction equivalent is setBackendProperty, which is what backend_properties uses.
  function applyBackendProperties() {
    var values = renderer.prop("backend_properties", {}) || {}
    var names = Object.keys(values).sort()
    for (var index = 0; index < names.length; index++) {
      var name = names[index]
      if (!nativeSource.setBackendProperty(name, values[name]))
        renderer.componentError("position_backend_property_rejected", "The positioning backend rejected a property", { property: name })
    }
  }
  function publish() {
    var position = nativeSource.position
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "position", {
      coordinate: coordinatePayload(position.coordinate), timestamp: timestampPayload(position.timestamp),
      latitude: position.coordinate.latitude, longitude: position.coordinate.longitude,
      altitude: position.coordinate.altitude, horizontal_accuracy: position.horizontalAccuracy,
      vertical_accuracy: position.verticalAccuracy, direction: position.direction,
      ground_speed: position.speed, vertical_speed: position.verticalSpeed,
      magnetic_variation: position.magneticVariation,
      latitude_valid: position.latitudeValid, longitude_valid: position.longitudeValid,
      altitude_valid: position.altitudeValid,
      direction_valid: position.directionValid, speed_valid: position.speedValid,
      vertical_speed_valid: position.verticalSpeedValid,
      horizontal_accuracy_valid: position.horizontalAccuracyValid,
      vertical_accuracy_valid: position.verticalAccuracyValid,
      source_valid: nativeSource.valid === true,
      supported_methods: Number(nativeSource.supportedPositioningMethods)
    })
  }
  function runCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    if (command === "") return
    if (command === "start") { nativeSource.start(); return }
    if (command === "stop") { nativeSource.stop(); return }
    if (command === "update") { nativeSource.update(Number(renderer.prop("update_timeout", 0))); return }
    renderer.componentError("position_command_rejected", "The position source does not support the requested command", { command: command })
  }
  function refresh() {
    applyBackendProperties()
    runCommand()
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }
  PositionSource {
    id: nativeSource
    active: renderer.prop("active", false) === true
    updateInterval: Number(renderer.prop("update_interval", 1000))
    preferredPositioningMethods: root.preferredMethods()
    name: String(renderer.prop("name", ""))
    onPositionChanged: root.publish()
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
    onValidityChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "valid_change", { value: nativeSource.valid })
    onSupportedPositioningMethodsChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "methods_change", { value: Number(supportedPositioningMethods) })
    onSourceErrorChanged: if (sourceError !== PositionSource.NoError) renderer.componentError("position_source_failed", "The native positioning backend reported an error", { native_code: Number(sourceError) })
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
