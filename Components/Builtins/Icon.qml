import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Text {
  required property var renderer
      text: renderer.iconGlyph(renderer.prop("name", renderer.prop("text", "")))
      textFormat: Text.PlainText
      color: renderer.prop("color", renderer.foreground)
      font.family: renderer.iconFontFamilyFor(renderer.prop("name", renderer.prop("text", "")))
      font.pixelSize: Number(renderer.prop("size", Style.font.icon))
    }
