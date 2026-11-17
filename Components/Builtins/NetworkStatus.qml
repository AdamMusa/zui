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

  function publish(eventName) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, payload())
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
    function onReachabilityChanged() { root.publish("change") }
    function onIsBehindCaptivePortalChanged() { root.publish("change") }
    function onTransportMediumChanged() { root.publish("change") }
    function onIsMeteredChanged() { root.publish("change") }
  }
}
