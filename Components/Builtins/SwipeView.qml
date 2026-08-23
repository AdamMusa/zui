import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.SwipeView {
  id: swipeRoot

  required property var renderer
  readonly property int requestedIndex: Number(renderer.prop("current_index", 0))
  property bool synchronizing: false
  property bool initialized: false

  function boundedIndex(value) {
    return count === 0 ? -1 : Math.max(0, Math.min(count - 1, Number(value)))
  }

  function syncSelection() {
    var next = boundedIndex(requestedIndex)
    if (currentIndex === next) return
    synchronizing = true
    currentIndex = next
    synchronizing = false
  }

  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 420))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  interactive: renderer.prop("interactive", true) !== false
  orientation: String(renderer.prop("orientation", "horizontal")) === "vertical"
    ? Qt.Vertical : Qt.Horizontal
  clip: renderer.prop("clip", true) !== false
  LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
  LayoutMirroring.childrenInherit: true

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  Repeater {
    model: renderer.node.children || []
    delegate: renderer.childDelegateComponent
  }

  Component.onCompleted: {
    initialized = true
    syncSelection()
  }
  onRequestedIndexChanged: syncSelection()
  onCountChanged: {
    syncSelection()
    if (initialized && renderer.subscribed("count_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "count_change", { value: count })
  }
  onCurrentIndexChanged: {
    if (synchronizing || currentIndex < 0) return
    if (renderer.subscribed("input"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: currentIndex })
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: currentIndex })
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
