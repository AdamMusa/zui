import QtQuick
import QtPositioning

Item {
  id: root
  required property var renderer
  property int handledRefreshRevision: -1
  property int handledCommandRevision: -1
  readonly property var systemNames: ["undefined", "gps", "glonass", "galileo", "beidou", "qzss", "multiple", "custom"]
  visible: false
  function systemName(system) {
    var index = Number(system)
    return index >= 0 && index < systemNames.length ? systemNames[index] : "custom"
  }
  function payload(satellites) {
    var result = []
    for (var index = 0; index < satellites.length; index++) {
      var satellite = satellites[index]
      var entry = { identifier: satellite.satelliteIdentifier, signal_strength: satellite.signalStrength,
        system: Number(satellite.satelliteSystem), system_name: systemName(satellite.satelliteSystem),
        has_elevation: satellite.hasAttribute(GeoSatelliteInfo.Elevation),
        has_azimuth: satellite.hasAttribute(GeoSatelliteInfo.Azimuth) }
      if (entry.has_elevation) entry.elevation = satellite.attribute(GeoSatelliteInfo.Elevation)
      if (entry.has_azimuth) entry.azimuth = satellite.attribute(GeoSatelliteInfo.Azimuth)
      result.push(entry)
    }
    return result
  }
  function publish(name, satellites) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name,
      { satellites: payload(satellites), count: satellites.length, valid: nativeSource.valid === true })
  }
  // SatelliteSource.parameters is a read-only default-property list consumed while the backend
  // is created, so zui drives post-construction configuration through setBackendProperty.
  function applyBackendProperties() {
    var values = renderer.prop("backend_properties", {}) || {}
    var names = Object.keys(values).sort()
    for (var index = 0; index < names.length; index++) {
      var name = names[index]
      if (!nativeSource.setBackendProperty(name, values[name]))
        renderer.componentError("satellite_backend_property_rejected", "The satellite backend rejected a property", { property: name })
    }
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
    renderer.componentError("satellite_command_rejected", "The satellite source does not support the requested command", { command: command })
  }
  function refresh() {
    applyBackendProperties()
    runCommand()
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish("in_view", nativeSource.satellitesInView)
    publish("in_use", nativeSource.satellitesInUse)
  }
  SatelliteSource {
    id: nativeSource
    active: renderer.prop("active", false) === true
    updateInterval: Number(renderer.prop("update_interval", 1000))
    name: String(renderer.prop("name", ""))
    onSatellitesInViewChanged: root.publish("in_view", satellitesInView)
    onSatellitesInUseChanged: root.publish("in_use", satellitesInUse)
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
    onValidityChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "valid_change", { value: nativeSource.valid })
    onSourceErrorChanged: if (sourceError !== SatelliteSource.NoError) renderer.componentError("satellite_source_failed", "The native satellite backend reported an error", { native_code: Number(sourceError) })
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
