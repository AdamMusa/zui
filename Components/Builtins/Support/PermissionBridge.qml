import QtQuick

Item {
  id: root
  required property var renderer
  required property var permission
  property int handledRequestRevision: -1
  property int lastPublishedNativeStatus: -1
  property bool publishing: false
  visible: false

  function statusName(value) {
    var names = ["undetermined", "granted", "denied"]
    return names[Number(value)] || "unknown"
  }
  function publish() {
    var nativeStatus = Number(permission.status)
    if (nativeStatus === lastPublishedNativeStatus) return
    if (publishing) return
    publishing = true
    lastPublishedNativeStatus = nativeStatus
    var name = statusName(nativeStatus)
    var payload = { status: name, native_status: nativeStatus }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    if (name === "granted" || name === "denied")
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload)
    publishing = false
  }
  function synchronizeRequest() {
    var revision = Number(renderer.prop("request_revision", 0))
    if (revision !== handledRequestRevision) {
      var first = handledRequestRevision < 0
      handledRequestRevision = revision
      if (!first || revision > 0) permission.request()
    }
  }
  Component.onCompleted: {
    synchronizeRequest()
    if (renderer.prop("auto_request", false) === true && Number(permission.status) === 0)
      permission.request()
    else
      publish()
  }
  Connections {
    target: root.permission
    function onStatusChanged() { root.publish() }
  }
  Connections {
    target: root.renderer
    function onNodeChanged() { root.synchronizeRequest() }
  }
}
