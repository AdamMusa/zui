import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Text {
  required property var renderer
      text: String(renderer.prop("text", ""))
      textFormat: Text.PlainText
      color: renderer.prop("color", renderer.foreground)
      font.family: renderer.fontFamily
      font.pixelSize: {
        var style = String(renderer.prop("style", "body"))
        if (style === "heading") return Style.font.heading
        if (style === "caption") return Style.font.caption
        return Number(renderer.prop("size", Style.font.body))
      }
      font.bold: renderer.prop("bold", false) || String(renderer.prop("style", "body")) === "heading"
      wrapMode: renderer.prop("wrap", true) ? Text.Wrap : Text.NoWrap
      width: Number(renderer.prop("width", implicitWidth))
    }
