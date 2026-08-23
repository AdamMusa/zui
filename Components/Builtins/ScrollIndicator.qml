import QtQuick
import QtQuick.Controls as QQC

QQC.ScrollIndicator {
  id: indicatorRoot
  property var renderer: null
  readonly property var scrollTarget: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  orientation: String(renderer ? renderer.prop("orientation", "vertical") : "vertical") === "horizontal" ? Qt.Horizontal : Qt.Vertical
  position: scrollTarget && scrollTarget.visibleArea ? (orientation === Qt.Vertical ? scrollTarget.visibleArea.yPosition : scrollTarget.visibleArea.xPosition) : Number(renderer ? renderer.prop("position", 0) : 0)
  size: scrollTarget && scrollTarget.visibleArea ? (orientation === Qt.Vertical ? scrollTarget.visibleArea.heightRatio : scrollTarget.visibleArea.widthRatio) : Number(renderer ? renderer.prop("size", 0.2) : 0.2)
  active: renderer && renderer.prop("active", false) === true
  minimumSize: Number(renderer ? renderer.prop("minimum_size", 0) : 0)
  implicitWidth: Number(renderer ? renderer.prop("width", orientation === Qt.Vertical ? 6 : 160) : 6); implicitHeight: Number(renderer ? renderer.prop("height", orientation === Qt.Vertical ? 160 : 6) : 160)
  onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
}
