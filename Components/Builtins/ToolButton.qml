import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.ToolButton {
  required property var renderer
      id: nativeToolButton
      text: String(renderer.prop("text", ""))
      checkable: renderer.prop("checkable", false) === true
      checked: renderer.prop("checked", false) === true
      enabled: renderer.prop("enabled", true) !== false
      implicitWidth: Number(renderer.prop("width", 40))
      implicitHeight: Number(renderer.prop("height", 36))
      background: Rectangle {
        radius: Style.cornerRadius
        color: nativeToolButton.checked
          ? renderer.prop("checked_background", renderer.prop("accent", Color.accent))
          : renderer.prop("background", nativeToolButton.hovered ? Color.popups.background : "transparent")
        border.width: nativeToolButton.activeFocus ? Style.normalBorderWidth : 0
        border.color: renderer.prop("accent", Color.accent)
        opacity: nativeToolButton.down ? 0.72 : 1
      }
      contentItem: Text {
        text: String(renderer.prop("icon", "")).length > 0 ? renderer.iconGlyph(renderer.prop("icon", "")) : nativeToolButton.text
        textFormat: Text.PlainText
        color: nativeToolButton.checked ? Color.background : renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("icon", "")).length > 0
          ? renderer.iconFontFamilyFor(renderer.prop("icon", ""))
          : String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(String(renderer.prop("icon", "")).length > 0 ? renderer.prop("icon_size", Style.font.icon) : renderer.prop("font_size", Style.font.body))
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { checked: checked })
      onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: checked })
      onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", {})
      onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", {})
      onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
    }
