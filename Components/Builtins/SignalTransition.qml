import QtQuick

// A signal_transition is a QObject, not an Item, so this adapter only declares the
// signal_transition to its enclosing state_machine, which owns the real hierarchy and
// addresses this node's own events back to it.
Item {
  id: signalTransitionRoot

  required property var renderer
  readonly property var description: ({
    on: String(renderer.prop("on", "")),
    target: String(renderer.prop("target", ""))
  })

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", description)
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { signalTransitionRoot.publish() } }
}
