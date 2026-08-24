import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Pane {
  id: railRoot

  required property var renderer
  readonly property var destinations: renderer.prop("items", [])
  readonly property int requestedIndex: Number(renderer.prop("current_index", 0))
  readonly property bool extended: renderer.prop("extended", false) === true
  property int currentIndex: 0
  property bool synchronizing: false

  function itemAt(index) {
    return Array.isArray(destinations) && index < destinations.length ? destinations[index] : null
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
    var count = Array.isArray(destinations) ? destinations.length : 0
    return count === 0 ? -1 : Math.max(0, Math.min(count - 1, Number(value)))
  }

  function syncSelection() {
    var next = boundedIndex(requestedIndex)
    if (currentIndex === next) return
    synchronizing = true
    currentIndex = next
    synchronizing = false
  }

  implicitWidth: Number(renderer.prop("width", extended ? 220 : 72))
  implicitHeight: Number(renderer.prop("height", 480))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.md))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Item {
    Column {
      id: destinationColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: String(renderer.prop("alignment", "top")) === "top" ? parent.top : undefined
      anchors.verticalCenter: String(renderer.prop("alignment", "top")) === "center"
        ? parent.verticalCenter : undefined
      anchors.bottom: String(renderer.prop("alignment", "top")) === "bottom" ? parent.bottom : undefined
      spacing: Number(renderer.prop("spacing", Style.spacing.sm))

      Repeater {
        model: Array.isArray(railRoot.destinations) ? railRoot.destinations.length : 0
        QQC.ToolButton {
          required property int index
          width: destinationColumn.width
          height: Number(renderer.prop("item_height", 56))
          enabled: railRoot.enabled && railRoot.itemValue(index, "enabled", true) !== false
          checkable: true
          checked: railRoot.currentIndex === index
          hoverEnabled: true

          contentItem: Row {
            property bool selected: parent.checked
            property bool available: parent.enabled
            anchors.centerIn: parent
            spacing: railRoot.extended ? Style.spacing.md : 0

            Image {
              visible: source.toString().length > 0
              source: String(railRoot.itemValue(index, "icon_source", ""))
              width: Number(renderer.prop("icon_size", Style.font.icon))
              height: width
              fillMode: Image.PreserveAspectFit
              onStatusChanged: {
                if (status === Image.Error)
                  renderer.componentError("navigation_rail_icon_failed",
                    "Unable to load the declared navigation rail icon image",
                    { index: index, source: String(source) })
              }
            }

            Text {
              visible: String(railRoot.itemValue(index, "icon_source", "")).length === 0
              text: renderer.iconGlyph(railRoot.itemValue(index, "icon", "circle_info"))
              color: parent.selected ? renderer.prop("accent", Color.accent)
                : (parent.available ? renderer.prop("foreground", renderer.foreground)
                  : renderer.prop("muted", Color.muted))
              font.family: renderer.iconFontFamilyFor(railRoot.itemValue(index, "icon", "circle_info"))
              font.pixelSize: Number(renderer.prop("icon_size", Style.font.icon))
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              visible: railRoot.extended
              text: railRoot.itemLabel(index)
              color: parent.selected ? renderer.prop("accent", Color.accent)
                : (parent.available ? renderer.prop("foreground", renderer.foreground)
                  : renderer.prop("muted", Color.muted))
              font.family: String(renderer.prop("font_family", renderer.fontFamily))
              font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
              anchors.verticalCenter: parent.verticalCenter
              elide: Text.ElideRight
            }
          }

          background: Rectangle {
            color: parent.checked ? renderer.prop("selected_background", "transparent") : "transparent"
            radius: Number(renderer.prop("radius", Style.cornerRadius))
          }

          onClicked: {
            railRoot.currentIndex = index
            if (renderer.subscribed("select"))
              renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select",
                { value: index, label: railRoot.itemLabel(index) })
          }
        }
      }
    }
  }

  onRequestedIndexChanged: syncSelection()
  onDestinationsChanged: syncSelection()
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
