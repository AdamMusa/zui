import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Text {
  id: root
  required property var renderer
      function synchronizeWidth() {
        var resolved = renderer.hasProp("width") ? Number(renderer.prop("width", 0)) : implicitWidth
        if (!isNaN(resolved) && width !== resolved) width = resolved
      }
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
      onTextChanged: Qt.callLater(root.synchronizeWidth)
      Component.onCompleted: synchronizeWidth()
      Connections {
        target: root.renderer
        function onNodeChanged() { Qt.callLater(root.synchronizeWidth) }
      }
    }
