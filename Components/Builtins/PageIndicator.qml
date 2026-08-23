import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.PageIndicator {
  id: indicatorRoot

  required property var renderer
  readonly property int requestedIndex: Number(renderer.prop("current_index", 0))
  property bool synchronizing: false

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

  count: Math.max(0, Number(renderer.prop("count", 0)))
  interactive: renderer.prop("interactive", false) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  spacing: Number(renderer.prop("spacing", Style.spacing.sm))
  implicitWidth: Number(renderer.prop("width",
    count * Number(renderer.prop("dot_size", 8)) + Math.max(0, count - 1) * spacing))
  implicitHeight: Number(renderer.prop("height", Number(renderer.prop("dot_size", 8)) + 12))

  background: Rectangle {
    color: renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", 0))
  }

  delegate: Rectangle {
    required property int index
    implicitWidth: Number(renderer.prop("dot_size", 8))
    implicitHeight: implicitWidth
    radius: width / 2
    color: index === indicatorRoot.currentIndex
      ? renderer.prop("accent", Color.accent)
      : renderer.prop("foreground", renderer.foreground)
    opacity: index === indicatorRoot.currentIndex ? 1 : 0.45
  }

  onRequestedIndexChanged: syncSelection()
  onCountChanged: syncSelection()
  Component.onCompleted: syncSelection()
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
