import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.Label {
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
      color: renderer.prop("color", renderer.foreground)
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
