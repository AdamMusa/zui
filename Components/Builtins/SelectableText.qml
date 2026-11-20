import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

TextEdit {
  id: root
  required property var renderer
      function synchronizeWidth() {
        // Qt.callLater owns nothing. Replacing a page queues a width sync for
        // every text node on it and then destroys them, and the callbacks
        // still run — against a renderer whose functions have already gone,
        // reporting "Property 'hasProp' of object ControlNode is not a
        // function" during delayed function evaluation. The node being
        // measured is the only reason to measure, so with it gone there is
        // nothing left to do.
        if (!renderer || typeof renderer.hasProp !== "function") return
        var resolved = renderer.hasProp("width") ? Number(renderer.prop("width", 0)) : implicitWidth
        if (!isNaN(resolved) && width !== resolved) width = resolved
      }
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
      onTextChanged: Qt.callLater(root.synchronizeWidth)
      Component.onCompleted: synchronizeWidth()
      Connections {
        target: root.renderer
        function onNodeChanged() { Qt.callLater(root.synchronizeWidth) }
      }
      wrapMode: renderer.prop("wrap", true) !== false ? TextEdit.Wrap : TextEdit.NoWrap
      textFormat: {
        var format = String(renderer.prop("format", "plain"))
        if (format === "rich") return TextEdit.RichText
        if (format === "markdown") return TextEdit.MarkdownText
        return TextEdit.PlainText
      }
      onSelectedTextChanged: if (renderer && renderer.bridge) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection", {
        start: selectionStart, end: selectionEnd, text: selectedText
      })
      onLinkActivated: function(link) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link", { value: link }) }
    }
