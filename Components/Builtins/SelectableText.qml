import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

TextEdit {
  required property var renderer
      text: String(renderer.prop("text", ""))
      readOnly: true
      selectByMouse: true
      persistentSelection: true
      color: renderer.prop("color", renderer.foreground)
      selectionColor: renderer.prop("selection_color", Color.accent)
      selectedTextColor: renderer.prop("selected_text_color", Color.background)
      font.family: renderer.fontFamily
      font.pixelSize: Number(renderer.prop("size", Style.font.body))
      font.bold: renderer.prop("bold", false) === true
      width: Number(renderer.prop("width", implicitWidth))
      wrapMode: renderer.prop("wrap", true) !== false ? TextEdit.Wrap : TextEdit.NoWrap
      textFormat: {
        var format = String(renderer.prop("format", "plain"))
        if (format === "rich") return TextEdit.RichText
        if (format === "markdown") return TextEdit.MarkdownText
        return TextEdit.PlainText
      }
      onSelectedTextChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection", {
        start: selectionStart, end: selectionEnd, text: selectedText
      })
      onLinkActivated: function(link) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link", { value: link }) }
    }
