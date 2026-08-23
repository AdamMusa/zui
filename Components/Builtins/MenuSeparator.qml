import QtQuick
import QtQuick.Controls as QQC

QQC.MenuSeparator {
  id: separatorRoot

  required property var renderer

  implicitWidth: Number(renderer.prop("width", 220))
  implicitHeight: Number(renderer.prop("height",
    Number(renderer.prop("thickness", 1)) + Number(renderer.prop("padding", 8)) * 2))
  padding: Number(renderer.prop("padding", 8))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  opacity: Number(renderer.prop("opacity", 0.25))

  contentItem: Item {}
  background: Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: separatorRoot.padding
    anchors.rightMargin: separatorRoot.padding
    height: Number(renderer.prop("thickness", 1))
    color: renderer.prop("color", renderer.foreground)
  }

  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
