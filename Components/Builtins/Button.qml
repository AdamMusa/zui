import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

Rectangle {
  id: root
  required property var renderer

  readonly property bool selected: renderer.prop("selected", false) === true
  readonly property bool active: renderer.prop("active", false) === true
  readonly property bool interactive: renderer.prop("enabled", true) !== false
  readonly property color foregroundColor: renderer.prop("foreground", renderer.foreground)
  readonly property color accentColor: renderer.prop("accent", Color.accent)
  readonly property real horizontalPad: Number(renderer.prop("horizontal_padding", Style.spacing.controlPaddingX))
  readonly property real verticalPad: Number(renderer.prop("vertical_padding", Style.spacing.controlPaddingY))

  activeFocusOnTab: renderer.prop("focusable", true) !== false
  implicitWidth: content.implicitWidth + horizontalPad * 2
  implicitHeight: Math.max(44, content.implicitHeight + verticalPad * 2)
  radius: Style.cornerRadius
  color: selected || active ? accentColor : renderer.prop("background", "transparent")
  border.width: renderer.prop("bordered", true) !== false ? Style.normalBorderWidth : 0
  border.color: selected || active ? accentColor
    : Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.3)
  opacity: !interactive ? 0.5 : (tap.pressed ? 0.78 : (hover.hovered ? 0.9 : 1))

  Row {
    id: content
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: renderer.prop("left_align", false) === true ? parent.left : undefined
    anchors.leftMargin: root.horizontalPad
    anchors.horizontalCenter: renderer.prop("left_align", false) === true ? undefined : parent.horizontalCenter
    spacing: String(renderer.prop("icon", "")) !== "" && String(renderer.prop("text", "")) !== ""
      ? Style.spacing.controlGap : 0

    Text {
      visible: String(renderer.prop("icon", "")) !== ""
      text: renderer.iconGlyph(renderer.prop("icon", ""))
      textFormat: Text.PlainText
      color: root.selected || root.active ? Color.background : root.foregroundColor
      font.family: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
      font.pixelSize: Number(renderer.prop("icon_size", Style.font.icon))
      rotation: Number(renderer.prop("icon_rotation", 0))
      NumberAnimation on rotation {
        running: renderer.prop("icon_spinning", false) === true
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
      }
    }

    Text {
      visible: String(renderer.prop("text", "")) !== ""
      text: String(renderer.prop("text", ""))
      textFormat: Text.PlainText
      color: root.selected || root.active ? Color.background : root.foregroundColor
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
  }

  TapHandler {
    id: tap
    enabled: root.interactive
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onTapped: function(point, button) {
      if (button === Qt.RightButton) {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "right_click", {})
        return
      }
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
      var url = String(renderer.prop("url", ""))
      if (url === "") return
      var opened = Qt.openUrlExternally(url)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, opened ? "open" : "error", { url: url })
    }
  }

  HoverHandler {
    id: hover
    enabled: root.interactive
    onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "hover", { value: hovered })
  }

  QQC.ToolTip.visible: hover.hovered && String(renderer.prop("tooltip", "")) !== ""
  QQC.ToolTip.text: String(renderer.prop("tooltip", ""))
}
