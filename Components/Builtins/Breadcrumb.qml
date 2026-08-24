import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Pane {
  id: breadcrumbRoot

  required property var renderer
  readonly property var destinations: renderer.prop("items", [])
  readonly property int requestedIndex: Number(renderer.prop("current_index",
    Array.isArray(destinations) ? destinations.length - 1 : -1))
  property int currentIndex: -1
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

  function itemPayload(index) {
    return {
      index: index,
      label: itemLabel(index),
      value: itemValue(index, "value", itemLabel(index))
    }
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

  implicitWidth: Number(renderer.prop("width", 560))
  implicitHeight: Number(renderer.prop("height", 48))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.sm))

  background: Rectangle {
    color: renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Flickable {
    clip: true
    contentWidth: trail.implicitWidth
    contentHeight: height
    interactive: contentWidth > width
    boundsBehavior: Flickable.StopAtBounds

    Row {
      id: trail
      height: parent.height
      spacing: Number(renderer.prop("spacing", Style.spacing.xs))

      Repeater {
        model: Array.isArray(breadcrumbRoot.destinations) ? breadcrumbRoot.destinations.length : 0
        Row {
          required property int index
          height: trail.height
          spacing: Number(renderer.prop("spacing", Style.spacing.xs))

          QQC.ToolButton {
            id: crumbButton
            height: Number(renderer.prop("item_height", trail.height))
            enabled: breadcrumbRoot.enabled && breadcrumbRoot.itemValue(index, "enabled", true) !== false
            hoverEnabled: true

            contentItem: Row {
              anchors.centerIn: parent
              spacing: Style.spacing.xs

              Image {
                visible: source.toString().length > 0
                source: String(breadcrumbRoot.itemValue(index, "icon_source", ""))
                width: Number(renderer.prop("icon_size", Style.font.icon))
                height: width
                fillMode: Image.PreserveAspectFit
                onStatusChanged: {
                  if (status === Image.Error)
                    renderer.componentError("breadcrumb_icon_failed",
                      "Unable to load the declared breadcrumb icon image",
                      { index: index, source: String(source) })
                }
              }

              Text {
                visible: String(breadcrumbRoot.itemValue(index, "icon", "")).length > 0
                  && String(breadcrumbRoot.itemValue(index, "icon_source", "")).length === 0
                text: renderer.iconGlyph(breadcrumbRoot.itemValue(index, "icon", ""))
                color: crumbButton.enabled ? renderer.prop("foreground", renderer.foreground)
                  : renderer.prop("muted", Color.muted)
                font.family: renderer.iconFontFamilyFor(breadcrumbRoot.itemValue(index, "icon", ""))
                font.pixelSize: Number(renderer.prop("icon_size", Style.font.icon))
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: breadcrumbRoot.itemLabel(index)
                color: !crumbButton.enabled ? renderer.prop("muted", Color.muted)
                  : (breadcrumbRoot.currentIndex === index ? renderer.prop("accent", Color.accent)
                    : renderer.prop("foreground", renderer.foreground))
                font.family: String(renderer.prop("font_family", renderer.fontFamily))
                font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
                font.bold: breadcrumbRoot.currentIndex === index
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            background: Rectangle { color: "transparent" }
            onClicked: {
              breadcrumbRoot.currentIndex = index
              if (renderer.subscribed("select"))
                renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                  "select", breadcrumbRoot.itemPayload(index))
            }
          }

          Text {
            visible: index < breadcrumbRoot.destinations.length - 1
            text: renderer.iconGlyph(renderer.prop("separator", "chevron_right"))
            color: renderer.prop("muted", Color.muted)
            font.family: renderer.iconFontFamilyFor(renderer.prop("separator", "chevron_right"))
            font.pixelSize: Number(renderer.prop("icon_size", Style.font.icon))
            anchors.verticalCenter: parent.verticalCenter
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
    var payload = itemPayload(currentIndex)
    if (renderer.subscribed("input"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload)
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
