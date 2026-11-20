import QtQuick
import QtSensors

Item {
  id: root
  required property var renderer
  property int handledRefreshRevision: -1
  visible: false

  function publish() {
    var types = QmlSensors.sensorTypes()
    var requested = String(renderer.prop("type", ""))
    var entries = []
    for (var index = 0; index < types.length; index++) {
      var type = String(types[index])
      if (requested !== "" && type !== requested) continue
      entries.push({
        type: type,
        identifiers: QmlSensors.sensorsForType(type),
        default_identifier: String(QmlSensors.defaultSensorForType(type))
      })
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "sensors", {
      types: types, sensors: entries, filtered_type: requested
    })
    if (requested !== "" && entries.length === 0)
      renderer.componentError("sensor_type_unavailable", "No sensor backend is registered for the requested type", { type: requested })
  }

  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }

  Connections {
    target: QmlSensors
    enabled: root.renderer.prop("watch", false) === true
    function onAvailableSensorsChanged() { root.publish() }
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
