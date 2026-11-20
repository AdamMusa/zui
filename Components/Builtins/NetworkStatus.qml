import QtQuick
import QtNetwork

Item {
  id: root
  required property var renderer
  property int handledRefreshRevision: -1
  visible: false

  function reachabilityName(value) {
    return ["unknown", "disconnected", "local", "site", "online"][Number(value)] || "unknown"
  }

  function transportName(value) {
    return ["unknown", "ethernet", "cellular", "wifi", "bluetooth"][Number(value)] || "unknown"
  }

  function payload() {
    return {
      reachability: reachabilityName(NetworkInformation.reachability),
      native_reachability: Number(NetworkInformation.reachability),
      captive_portal: NetworkInformation.isBehindCaptivePortal,
      transport: transportName(NetworkInformation.transportMedium),
      native_transport: Number(NetworkInformation.transportMedium),
      metered: NetworkInformation.isMetered
    }
  }

  // QNetworkInformation exposes Reachability, CaptivePortal, TransportMedium and Metered
  // as a Features flag set in C++, but supports() is not invokable from QML in 6.8.3, so
  // an unsupported facet cannot be told apart from a genuine Unknown/false reading here.
  property var pendingChanges: []

  function publish(eventName) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, payload())
  }

  function queueChange(field) {
    if (pendingChanges.indexOf(field) < 0) pendingChanges.push(field)
    changeTimer.restart()
  }

  function publishChange() {
    var values = payload()
    values.changed = pendingChanges.slice()
    pendingChanges = []
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", values)
  }

  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish("information")
  }

  Component.onCompleted: refresh()
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Connections {
    target: NetworkInformation
    enabled: root.renderer.prop("watch", true) !== false
    function onReachabilityChanged() { root.queueChange("reachability") }
    function onIsBehindCaptivePortalChanged() { root.queueChange("captive_portal") }
    function onTransportMediumChanged() { root.queueChange("transport") }
    function onIsMeteredChanged() { root.queueChange("metered") }
  }
  // Moving between networks moves several of these at once, so coalesce the signals into
  // one change event that names the fields that moved.
  Timer { id: changeTimer; interval: 16; repeat: false; onTriggered: root.publishChange() }
}
