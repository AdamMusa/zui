import QtQuick
import QtNetwork

Item {
  id: root
  required property var renderer
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

  Component.onCompleted: publish("information")
  Connections { target: renderer; function onNodeChanged() { root.publish("information") } }
  Connections {
    target: NetworkInformation
    enabled: root.renderer.prop("watch", true) !== false
    function onReachabilityChanged() { root.publish("change") }
    function onIsBehindCaptivePortalChanged() { root.publish("change") }
    function onTransportMediumChanged() { root.publish("change") }
    function onIsMeteredChanged() { root.publish("change") }
  }
}
