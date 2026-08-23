import QtQuick

Item {
  id: actionRoot
  property var renderer: null
  property int handledRevision: -1
  function run() {
    if (!renderer) return
    var revision = Number(renderer.prop("revision", 0)); if (revision === handledRevision || renderer.prop("trigger", true) === false) return
    handledRevision = revision; nativeAction.start()
  }
  ScriptAction { id: nativeAction; script: function() { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "trigger", { action: renderer.prop("action", null), revision: actionRoot.handledRevision }); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "finish", {}) } }
  Component.onCompleted: run()
  Connections { target: renderer; function onNodeChanged() { actionRoot.run() } }
}
