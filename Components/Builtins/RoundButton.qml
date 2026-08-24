import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.RoundButton {
  required property var renderer
      id: nativeRoundButton
      text: String(renderer.prop("text", ""))
      checkable: renderer.prop("checkable", false) === true
      checked: renderer.prop("checked", false) === true
      enabled: renderer.prop("enabled", true) !== false
      implicitWidth: Number(renderer.prop("diameter", 44))
      implicitHeight: implicitWidth
      background: Rectangle {
        radius: width / 2
        color: nativeRoundButton.checked
          ? renderer.prop("checked_background", renderer.prop("accent", Color.accent))
          : renderer.prop("background", Color.popups.background)
        border.width: Style.normalBorderWidth
        border.color: nativeRoundButton.activeFocus ? renderer.prop("accent", Color.accent) : renderer.prop("foreground", renderer.foreground)
        opacity: nativeRoundButton.down ? 0.75 : (nativeRoundButton.hovered ? 0.9 : 1)
      }
      contentItem: Text {
        text: String(renderer.prop("icon", "")).length > 0 ? renderer.iconGlyph(renderer.prop("icon", "")) : nativeRoundButton.text
        textFormat: Text.PlainText
        color: nativeRoundButton.checked ? Color.background : renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("icon", "")).length > 0
          ? renderer.iconFontFamilyFor(renderer.prop("icon", ""))
          : String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(String(renderer.prop("icon", "")).length > 0 ? renderer.prop("icon_size", Style.font.icon) : renderer.prop("font_size", Style.font.body))
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { checked: checked })
      onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: checked })
      onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", {})
      onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", {})
      onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
    }
