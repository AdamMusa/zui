import QtQuick

// A machine_state is a QObject, not an Item, so this adapter only declares the
// machine_state to its enclosing state_machine, which owns the real hierarchy and
// addresses this node's own events back to it.
Item {
  id: machineStateRoot

  required property var renderer
  readonly property var description: ({
    name: String(renderer.prop("name", "")),
    initial: renderer.prop("initial", false) === true,
    child_mode: String(renderer.prop("child_mode", "exclusive")),
    error_state: String(renderer.prop("error_state", ""))
  })

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", description)
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { machineStateRoot.publish() } }
}
