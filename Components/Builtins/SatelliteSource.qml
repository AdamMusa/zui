import QtQuick
import QtPositioning

Item {
  id: root
  required property var renderer
  property int handledRefreshRevision: -1
  visible: false
  function payload(satellites) {
    var result = []
    for (var index = 0; index < satellites.length; index++) {
      var satellite = satellites[index]
      result.push({ identifier: satellite.satelliteIdentifier, signal_strength: satellite.signalStrength,
        system: Number(satellite.satelliteSystem) })
    }
    return result
  }
  function publish(name, satellites) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, { satellites: payload(satellites) })
  }
  function refresh() {
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
    onSourceErrorChanged: if (sourceError !== SatelliteSource.NoError) renderer.componentError("satellite_source_failed", "The native satellite backend reported an error", { native_code: Number(sourceError) })
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
