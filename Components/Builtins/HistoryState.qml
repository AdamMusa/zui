import QtQuick

// A history_state is a QObject, not an Item, so this adapter only declares the
// history_state to its enclosing state_machine, which owns the real hierarchy and
// addresses this node's own events back to it.
Item {
  id: historyStateRoot

  required property var renderer
  readonly property var description: ({
    name: String(renderer.prop("name", "")),
    history_type: String(renderer.prop("history_type", "shallow")),
    default_state: String(renderer.prop("default_state", ""))
  })

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", description)
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { historyStateRoot.publish() } }
}
