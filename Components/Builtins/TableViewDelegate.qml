import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.ItemDelegate {
  id: delegateRoot
  property var renderer: null
  text: renderer ? String(renderer.prop("text", "")) : ""
  implicitWidth: Number(renderer ? renderer.prop("width", 160) : 160); implicitHeight: Number(renderer ? renderer.prop("height", 42) : 42)
  highlighted: renderer && (renderer.prop("selected", false) === true || renderer.prop("current", false) === true)
  enabled: !renderer || renderer.prop("enabled", true) !== false
  font.family: renderer ? renderer.prop("font_family", renderer.fontFamily) : ""; font.pixelSize: Number(renderer ? renderer.prop("font_size", Style.font.body) : Style.font.body)
  background: Rectangle { color: delegateRoot.highlighted ? renderer.prop("selected_background", Color.popups.background) : renderer.prop("background", "transparent"); border.color: renderer.prop("border_color", "transparent") }
  contentItem: Text { text: delegateRoot.text; opacity: renderer.prop("editing", false) === true ? 0.45 : 1; color: delegateRoot.highlighted ? renderer.prop("selected_foreground", renderer.foreground) : renderer.prop("foreground", renderer.foreground); font: delegateRoot.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
  onClicked: { var payload={row:renderer.prop("row",-1),column:renderer.prop("column",-1),value:renderer.prop("value",null)};renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"click",payload);if(renderer.prop("editing",false)===true)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"edit",payload) }
  onDoubleClicked: { var payload={row:renderer.prop("row",-1),column:renderer.prop("column",-1),value:renderer.prop("value",null)};renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"double_click",payload);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"activate",payload) }
}
