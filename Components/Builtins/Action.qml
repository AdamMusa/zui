import QtQuick
import QtQuick.Controls as QQC

Item {
  id: actionRoot

  required property var renderer
  property alias nativeAction: nativeAction
  readonly property string actionId: renderer.controlId

  function payload() {
    return {
      value: nativeAction.checked,
      checked: nativeAction.checked,
      text: nativeAction.text
    }
  }

  implicitWidth: 0
  implicitHeight: 0
  visible: renderer.prop("visible", true) !== false

  QQC.Action {
    id: nativeAction
    text: String(renderer.prop("text", ""))
    enabled: renderer.prop("enabled", true) !== false && actionRoot.visible
    checkable: renderer.prop("checkable", false) === true
    checked: renderer.prop("checked", false) === true
    shortcut: renderer.prop("shortcut", "")
    icon.name: String(renderer.prop("icon", ""))
    icon.source: String(renderer.prop("icon_source", ""))
    icon.color: renderer.prop("icon_color", "transparent")
    icon.width: Number(renderer.prop("icon_width", 0))
    icon.height: Number(renderer.prop("icon_height", 0))

    onTriggered: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "trigger", actionRoot.payload())
    onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "toggle", actionRoot.payload())
    onCheckedChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "change", actionRoot.payload())
  }
}
