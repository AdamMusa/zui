import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.AbstractButton {
  id: control
  required property var renderer
  implicitWidth: Number(renderer.prop("width", Math.max(80, contentHost.childrenRect.width + leftPadding + rightPadding)))
  implicitHeight: Number(renderer.prop("height", Math.max(44, contentHost.childrenRect.height + topPadding + bottomPadding)))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  checkable: renderer.prop("checkable", false) === true
  checked: renderer.prop("checked", false) === true
  autoExclusive: renderer.prop("auto_exclusive", false) === true
  autoRepeat: renderer.prop("auto_repeat", false) === true
  autoRepeatDelay: Number(renderer.prop("auto_repeat_delay", 300))
  autoRepeatInterval: Number(renderer.prop("auto_repeat_interval", 100))
  padding: Number(renderer.prop("padding", 12))
  background: Rectangle {
    color: renderer.prop("background", Color.surface)
    border.color: renderer.prop("border_color", Color.border)
    radius: Number(renderer.prop("radius", 8))
  }
  contentItem: Item {
    id: contentHost
    implicitWidth: children.length > 1 ? childrenRect.width : nativeLabel.implicitWidth
    implicitHeight: children.length > 1 ? childrenRect.height : nativeLabel.implicitHeight
    Text {
      id: nativeLabel
      anchors.centerIn: parent
      visible: parent.children.length <= 1
      text: String(renderer.prop("text", ""))
      color: renderer.prop("foreground", renderer.foreground)
      font.family: renderer.prop("font_family", renderer.fontFamily)
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
  onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
  onDoubleClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_click", {})
  onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", {})
  onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", {})
  onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
  onPressAndHold: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press_and_hold", {})
  onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: checked })
}
