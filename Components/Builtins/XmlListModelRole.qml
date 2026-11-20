import QtQuick

Item {
  id: roleRoot

  required property var renderer
  readonly property string roleName: String(renderer.prop("name", ""))
  readonly property string elementName: String(renderer.prop("element_name", ""))
  readonly property string attributeName: String(renderer.prop("attribute_name", ""))
  readonly property var role: ({
    name: roleName, element_name: elementName, attribute_name: attributeName
  })

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", role)
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { roleRoot.publish() } }
}
