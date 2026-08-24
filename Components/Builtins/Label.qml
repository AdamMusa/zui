import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.Label {
  required property var renderer
      text: String(renderer.prop("text", ""))
      color: renderer.prop("color", renderer.foreground)
      font.family: renderer.fontFamily
      font.pixelSize: Number(renderer.prop("size", Style.font.body))
      font.bold: renderer.prop("bold", false) === true
      width: Number(renderer.prop("width", implicitWidth))
      wrapMode: renderer.prop("wrap", false) === true ? Text.Wrap : Text.NoWrap
      elide: {
        var mode = String(renderer.prop("elide", "none"))
        if (mode === "left") return Text.ElideLeft
        if (mode === "middle") return Text.ElideMiddle
        if (mode === "right") return Text.ElideRight
        return Text.ElideNone
      }
      horizontalAlignment: {
        var alignment = String(renderer.prop("horizontal_alignment", "left"))
        if (alignment === "center") return Text.AlignHCenter
        if (alignment === "right") return Text.AlignRight
        if (alignment === "justify") return Text.AlignJustify
        return Text.AlignLeft
      }
      verticalAlignment: String(renderer.prop("vertical_alignment", "center")) === "top" ? Text.AlignTop
        : (String(renderer.prop("vertical_alignment", "center")) === "bottom" ? Text.AlignBottom : Text.AlignVCenter)
      maximumLineCount: Number(renderer.prop("maximum_lines", 2147483647))
      textFormat: {
        var format = String(renderer.prop("format", "plain"))
        if (format === "rich") return Text.RichText
        if (format === "markdown") return Text.MarkdownText
        if (format === "styled") return Text.StyledText
        return Text.PlainText
      }
      onLinkActivated: function(link) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link", { value: link }) }
    }
