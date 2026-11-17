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
      textFormat: Text.RichText
      color: renderer.prop("color", renderer.foreground)
      linkColor: renderer.prop("link_color", Color.accent)
      font.family: renderer.fontFamily
      font.pixelSize: Number(renderer.prop("size", Style.font.body))
      font.bold: renderer.prop("bold", false) === true
      onTextChanged: Qt.callLater(root.synchronizeWidth)
      Component.onCompleted: synchronizeWidth()
      Connections {
        target: root.renderer
        function onNodeChanged() { Qt.callLater(root.synchronizeWidth) }
      }
      wrapMode: renderer.prop("wrap", true) !== false ? Text.Wrap : Text.NoWrap
      maximumLineCount: Number(renderer.prop("maximum_lines", 2147483647))
      onLinkActivated: function(link) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link", { value: link }) }
      HoverHandler { cursorShape: parent.hoveredLink.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor }
    }
