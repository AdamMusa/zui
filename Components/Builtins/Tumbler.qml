import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Tumbler {
  id: tumblerRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", 120) : 120); implicitHeight: Number(renderer ? renderer.prop("height", 220) : 220)
  model: renderer ? renderer.prop("items", []) : []
  currentIndex: Number(renderer ? renderer.prop("current_index", 0) : 0)
  visibleItemCount: Number(renderer ? renderer.prop("visible_item_count", 5) : 5)
  wrap: !renderer || renderer.prop("wrap", true) !== false
  enabled: !renderer || (renderer.prop("enabled", true) !== false && renderer.prop("interactive", true) !== false)
  font.family: renderer ? renderer.prop("font_family", renderer.fontFamily) : ""; font.pixelSize: Number(renderer ? renderer.prop("font_size", Style.font.body) : Style.font.body)
  background: Rectangle { color: renderer ? renderer.prop("background", "transparent") : "transparent" }
  delegate: Text { required property var modelData; required property int index; text: String(modelData); color: index === tumblerRoot.currentIndex ? renderer.prop("accent", renderer.prop("foreground", renderer.foreground)) : renderer.prop("muted", renderer.prop("foreground", renderer.foreground)); font: tumblerRoot.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; opacity: 1.0 - Math.min(0.7, Math.abs(QQC.Tumbler.displacement) / Math.max(1, tumblerRoot.visibleItemCount)) }
  onMovingChanged: if (!moving) { var payload = { value: currentIndex, item: model[currentIndex] }; renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload) }
}
