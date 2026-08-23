import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtMultimedia
import QtQuick.VectorImage
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.SearchField {
  required property var renderer
      id: nativeSearchField
      text: String(renderer.prop("text", ""))
      suggestionModel: renderer.prop("suggestions", [])
      textRole: String(renderer.prop("text_role", ""))
      live: renderer.prop("live", false) === true
      currentIndex: Number(renderer.prop("current_index", -1))
      enabled: renderer.prop("enabled", true) !== false
      implicitWidth: Number(renderer.prop("width", 260))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      palette.text: renderer.prop("foreground", renderer.foreground)
      palette.buttonText: renderer.prop("foreground", renderer.foreground)
      palette.button: renderer.prop("background", Color.popups.background)
      palette.highlight: renderer.prop("accent", Color.accent)
      palette.highlightedText: Color.background
      onTextEdited: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: text })
      onSearchTriggered: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "search", { value: text })
      onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "submit", { value: text })
      onActivated: function(index) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", { index: index, value: text }) }
      onHighlighted: function(index) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "highlight", { index: index }) }
      onClearButtonPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "clear", {})
      onActiveFocusChanged: {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", { value: text })
        if (!activeFocus && renderer.subscribed("change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: text })
      }
    }
