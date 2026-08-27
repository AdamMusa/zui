import QtQuick
import QtQuick.Controls as QQC

QQC.Control {
  id: control
  required property var renderer
  implicitWidth: Number(renderer.prop("width", Math.max(44, contentHost.childrenRect.width + leftPadding + rightPadding)))
  implicitHeight: Number(renderer.prop("height", Math.max(44, contentHost.childrenRect.height + topPadding + bottomPadding)))
  padding: Number(renderer.prop("padding", 0))
  leftPadding: Number(renderer.prop("left_padding", padding))
  topPadding: Number(renderer.prop("top_padding", padding))
  rightPadding: Number(renderer.prop("right_padding", padding))
  bottomPadding: Number(renderer.prop("bottom_padding", padding))
  enabled: renderer.prop("enabled", true) !== false
  focus: renderer.prop("focus", false) === true
  hoverEnabled: renderer.prop("hover_enabled", true) !== false
  clip: renderer.prop("clip", false) === true
  visible: renderer.prop("visible", true) !== false
  background: Rectangle {
    color: renderer.prop("background", "transparent")
    border.color: renderer.prop("border_color", "transparent")
    border.width: Number(renderer.prop("border_width", 0))
    radius: Number(renderer.prop("radius", 0))
  }
  contentItem: Item {
    id: contentHost
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
  TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {}) }
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", {})
  onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
}
