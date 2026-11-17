import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.MenuBarItem {
  id: item
  required property var renderer
  text: String(renderer.prop("text", ""))
  highlighted: renderer.prop("highlighted", false) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  implicitWidth: Number(renderer.prop("width", Math.max(44, contentItem.implicitWidth + leftPadding + rightPadding)))
  implicitHeight: Number(renderer.prop("height", 44))
  padding: Number(renderer.prop("padding", 10))
  font.family: renderer.prop("font_family", renderer.fontFamily)
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  contentItem: Text {
    text: item.text
    color: renderer.prop("foreground", renderer.foreground)
    font: item.font
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
  }
  background: Rectangle {
    color: item.highlighted ? renderer.prop("highlighted_background", Color.hover) : renderer.prop("background", "transparent")
  }
  onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
  onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", {})
  onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", {})
  onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
  onHighlightedChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "highlight", { value: highlighted })
}
