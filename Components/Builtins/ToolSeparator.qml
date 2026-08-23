import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.ToolSeparator {
  id: separatorRoot

  required property var renderer
  orientation: String(renderer.prop("orientation", "vertical")) === "vertical"
    ? Qt.Vertical : Qt.Horizontal
  implicitWidth: vertical
    ? Number(renderer.prop("thickness", 1)) + Number(renderer.prop("padding", 8)) * 2
    : Number(renderer.prop("length", 32))
  implicitHeight: vertical
    ? Number(renderer.prop("length", 32))
    : Number(renderer.prop("thickness", 1)) + Number(renderer.prop("padding", 8)) * 2
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  opacity: Number(renderer.prop("opacity", 0.25))
  padding: Number(renderer.prop("padding", 8))

  contentItem: Item {}
  background: Rectangle {
    anchors.centerIn: parent
    width: separatorRoot.vertical
      ? Number(renderer.prop("thickness", 1))
      : Number(renderer.prop("length", 32))
    height: separatorRoot.vertical
      ? Number(renderer.prop("length", 32))
      : Number(renderer.prop("thickness", 1))
    color: renderer.prop("color", renderer.foreground)
  }

  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
