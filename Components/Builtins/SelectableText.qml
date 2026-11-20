import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

TextEdit {
  id: root
  required property var renderer
      function synchronizeWidth() {
        // The sync is deferred through widthSyncTimer, a child of this node,
        // never through Qt.callLater: replacing a page queues a width sync for
        // every text node on it and then destroys them, and a callLater that
        // outlives its node runs against a dead context ("attempted to
        // evaluate a function in an invalid context", dozens per page switch)
        // or against a renderer whose functions have gone ("Property 'hasProp'
        // of object ControlNode is not a function"). The node being measured is
        // the only reason to measure, so with it gone there is nothing to do.
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
      onTextChanged: widthSyncTimer.restart()
      Component.onCompleted: synchronizeWidth()
      Timer {
        id: widthSyncTimer
        interval: 0
        repeat: false
        onTriggered: root.synchronizeWidth()
      }
      Connections {
        target: root.renderer
        function onNodeChanged() { widthSyncTimer.restart() }
      }
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
