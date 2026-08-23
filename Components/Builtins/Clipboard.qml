import QtQuick

Item {
  required property var renderer
  property int handledRevision: -1

  function synchronize() {
    var revision = Number(renderer.prop("revision", 0))
    var requested = renderer.prop("text", null)
    if (requested === null || revision === handledRevision) return
    handledRevision = revision
    zuiClipboard.text = String(requested)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "copied", {
      value: String(requested), revision: revision
    })
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { synchronize() } }
  Connections {
    target: zuiClipboard
    enabled: renderer.prop("watch", true) !== false
    function onTextChanged() {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
        value: zuiClipboard.text
      })
    }
  }
}
