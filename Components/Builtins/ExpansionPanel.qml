import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Control {
  id: panelRoot

  required property var renderer
  readonly property bool requestedExpanded: renderer.prop("expanded", false) === true
  readonly property real headerHeight: Number(renderer.prop("header_height", 64))
  readonly property real contentNaturalHeight: contentColumn.implicitHeight
    + Number(renderer.prop("padding", Style.spacing.lg)) * 2
  property bool expanded: false
  property bool synchronizing: false

  function syncExpanded() {
    if (expanded === requestedExpanded) return
    synchronizing = true
    expanded = requestedExpanded
    synchronizing = false
  }

  function activate() {
    if (!enabled) return
    expanded = !expanded
    var payload = { value: expanded, expanded: expanded }
    if (renderer.subscribed("toggle"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "toggle", payload)
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
    var direction = expanded ? "expand" : "collapse"
    if (renderer.subscribed(direction))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, direction, payload)
  }

  implicitWidth: Number(renderer.prop("width", 560))
  implicitHeight: renderer.prop("height", null) === null
    ? headerHeight + (expanded ? contentNaturalHeight : 0)
    : Number(renderer.prop("height", headerHeight + contentNaturalHeight))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false

  background: Rectangle {
    color: panelRoot.expanded
      ? renderer.prop("expanded_background", renderer.prop("background", Color.background))
      : renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Item {
    QQC.ToolButton {
      id: headerButton
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: panelRoot.headerHeight
      enabled: panelRoot.enabled
      hoverEnabled: true
      onClicked: panelRoot.activate()

      contentItem: Item {
        Text {
          id: titleText
          anchors.left: parent.left
          anchors.right: indicator.left
          anchors.top: String(renderer.prop("subtitle", "")).length > 0
            ? parent.top : undefined
          anchors.verticalCenter: String(renderer.prop("subtitle", "")).length === 0
            ? parent.verticalCenter : undefined
          text: String(renderer.prop("title", ""))
          color: renderer.prop("foreground", renderer.foreground)
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("title_size",
            renderer.prop("font_size", Style.font.body)))
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          anchors.left: parent.left
          anchors.right: indicator.left
          anchors.top: titleText.bottom
          text: String(renderer.prop("subtitle", ""))
          visible: text.length > 0
          color: renderer.prop("muted", Color.muted)
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("subtitle_size", Style.font.caption))
          elide: Text.ElideRight
        }

        Text {
          id: indicator
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: renderer.iconGlyph("chevron_down")
          color: renderer.prop("accent", Color.accent)
          font.family: renderer.iconFontFamily
          font.pixelSize: Number(renderer.prop("indicator_size", Style.font.icon))
          rotation: panelRoot.expanded ? 180 : 0
          Behavior on rotation {
            enabled: renderer.prop("animated", true) !== false
            NumberAnimation {
              duration: Number(renderer.prop("duration", 200))
              easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad"))
            }
          }
        }
      }

      background: Rectangle {
        color: renderer.prop("header_background", "transparent")
        radius: Number(renderer.prop("radius", Style.cornerRadius))
      }
    }

    Item {
      id: revealedContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: headerButton.bottom
      height: panelRoot.expanded ? panelRoot.contentNaturalHeight : 0
      clip: true
      opacity: panelRoot.expanded ? 1 : 0

      Behavior on height {
        enabled: renderer.prop("animated", true) !== false
        NumberAnimation {
          duration: Number(renderer.prop("duration", 200))
          easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad"))
        }
      }
      Behavior on opacity {
        enabled: renderer.prop("animated", true) !== false
        NumberAnimation { duration: Number(renderer.prop("duration", 120)) }
      }

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Number(renderer.prop("padding", Style.spacing.lg))
        spacing: Number(renderer.prop("spacing", Style.spacing.md))
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
  }

  onRequestedExpandedChanged: syncExpanded()
  Component.onCompleted: syncExpanded()
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
