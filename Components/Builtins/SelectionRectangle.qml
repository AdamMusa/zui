import QtQuick
import QtQuick.Controls as QQC

QQC.SelectionRectangle {
  id: selectionRoot
  property var renderer: null
  target: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  enabled: renderer && renderer.prop("enabled", true) !== false
  selectionMode: {
    var mode = String(renderer ? renderer.prop("mode", "auto") : "auto")
    if (mode === "drag") return QQC.SelectionRectangle.Drag
    if (mode === "press_and_hold") return QQC.SelectionRectangle.PressAndHold
    return QQC.SelectionRectangle.Auto
  }
  onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active, dragging: dragging })
  onDraggingChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection_change", { active: active, dragging: dragging })
}
