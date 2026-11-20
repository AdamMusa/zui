import QtQuick

// A timeout_transition is a QObject, not an Item, so this adapter only declares the
// timeout_transition to its enclosing state_machine, which owns the real hierarchy and
// addresses this node's own events back to it.
Item {
  id: timeoutTransitionRoot

  required property var renderer
  readonly property var description: ({
    timeout: Math.max(0, Math.floor(Number(renderer.prop("timeout", 0)))),
    target: String(renderer.prop("target", ""))
  })

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", description)
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { timeoutTransitionRoot.publish() } }
}
