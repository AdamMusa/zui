import QtQuick
import QtQuick.Controls as QQC

QQC.ScrollBar {
  id: barRoot
  property var renderer: null
  readonly property var scrollTarget: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  orientation: String(renderer ? renderer.prop("orientation", "vertical") : "vertical") === "horizontal" ? Qt.Horizontal : Qt.Vertical
  policy: { var value=String(renderer ? renderer.prop("policy", "as_needed") : "as_needed"); if(value==="always")return QQC.ScrollBar.AlwaysOn;if(value==="never")return QQC.ScrollBar.AlwaysOff;return QQC.ScrollBar.AsNeeded }
  position: scrollTarget && scrollTarget.visibleArea ? (orientation === Qt.Vertical ? scrollTarget.visibleArea.yPosition : scrollTarget.visibleArea.xPosition) : Number(renderer ? renderer.prop("position", 0) : 0)
  size: scrollTarget && scrollTarget.visibleArea ? (orientation === Qt.Vertical ? scrollTarget.visibleArea.heightRatio : scrollTarget.visibleArea.widthRatio) : Number(renderer ? renderer.prop("size", 0.2) : 0.2)
  active: renderer && renderer.prop("active", false) === true
  interactive: !renderer || renderer.prop("interactive", true) !== false
  stepSize: Number(renderer ? renderer.prop("step_size", 0.1) : 0.1); minimumSize: Number(renderer ? renderer.prop("minimum_size", 0) : 0)
  implicitWidth: Number(renderer ? renderer.prop("width", orientation === Qt.Vertical ? 12 : 160) : 12); implicitHeight: Number(renderer ? renderer.prop("height", orientation === Qt.Vertical ? 160 : 12) : 160)
  onPositionChanged: { if (pressed && scrollTarget) { if (orientation === Qt.Vertical) scrollTarget.contentY = position * Math.max(0, scrollTarget.contentHeight); else scrollTarget.contentX = position * Math.max(0, scrollTarget.contentWidth) } renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, pressed ? "input" : "change", { value: position, size: size }) }
  onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
}
