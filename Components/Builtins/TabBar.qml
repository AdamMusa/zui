import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.TabBar {
  id: barRoot

  required property var renderer
  readonly property var tabItems: renderer.prop("items", [])
  readonly property int requestedIndex: Number(renderer.prop("current_index", 0))
  property bool synchronizing: false

  function itemAt(index) {
    return Array.isArray(tabItems) && index < tabItems.length ? tabItems[index] : null
  }

  function itemValue(index, name, fallback) {
    var item = itemAt(index)
    return item !== null && typeof item === "object" && item[name] !== undefined
      ? item[name] : fallback
  }

  function itemLabel(index) {
    var item = itemAt(index)
    return item !== null && typeof item === "object"
      ? String(item.label === undefined ? (item.text === undefined ? "" : item.text) : item.label)
      : String(item === null ? "" : item)
  }

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

  implicitWidth: Number(renderer.prop("width", 480))
  implicitHeight: Number(renderer.prop("height", 44))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  spacing: Number(renderer.prop("spacing", 0))
  position: String(renderer.prop("position", "top")) === "bottom"
    ? QQC.TabBar.Footer : QQC.TabBar.Header
  LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
  LayoutMirroring.childrenInherit: true

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  Repeater {
    model: Array.isArray(barRoot.tabItems) ? barRoot.tabItems.length : 0
    QQC.TabButton {
      required property int index
      width: Number(renderer.prop("tab_width", 0)) > 0
        ? Number(renderer.prop("tab_width", 0))
        : Math.max(1, barRoot.width / Math.max(1, barRoot.count))
      height: barRoot.height
      text: barRoot.itemLabel(index)
      enabled: barRoot.itemValue(index, "enabled", true) !== false
      icon.name: String(barRoot.itemValue(index, "icon", ""))
      icon.source: String(barRoot.itemValue(index, "icon_source", ""))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      contentItem: Text {
        text: parent.text
        color: parent.checked ? renderer.prop("accent", Color.accent)
          : (parent.enabled ? renderer.prop("foreground", renderer.foreground)
            : renderer.prop("muted", Color.muted))
        font: parent.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }
      background: Rectangle {
        property bool selected: parent.checked
        color: "transparent"
        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: barRoot.position === QQC.TabBar.Header ? parent.bottom : undefined
          anchors.top: barRoot.position === QQC.TabBar.Footer ? parent.top : undefined
          height: parent.selected ? 2 : 0
          color: renderer.prop("accent", Color.accent)
        }
      }
      onClicked: {
        if (renderer.subscribed("tab_click"))
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
            "tab_click", { value: index, label: text })
      }
    }
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
