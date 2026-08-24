import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.ScrollView {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", 320))
      implicitHeight: Number(renderer.prop("height", 140))
      clip: true
      QQC.TextArea {
        id: nativeTextArea
        readonly property bool supportsTextEditedSignal: nativeTextArea["textEdited"] !== undefined
        function sendInputEvent() {
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: text })
        }
        text: String(renderer.prop("text", ""))
        placeholderText: String(renderer.prop("placeholder", ""))
        readOnly: renderer.prop("read_only", false) === true
        readonly property int maximumLengthValue: Number(renderer.prop("maximum_length", 32767))
        wrapMode: String(renderer.prop("wrap", "word")) === "none" ? TextEdit.NoWrap
          : (String(renderer.prop("wrap", "word")) === "anywhere" ? TextEdit.WrapAnywhere : TextEdit.Wrap)
        color: renderer.prop("foreground", renderer.foreground)
        selectionColor: renderer.prop("selection_tint", renderer.prop("accent", Color.accent))
        selectedTextColor: Color.background
        placeholderTextColor: Color.muted
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        padding: Number(renderer.prop("padding", Style.spacing.inputPaddingY))
        background: Rectangle {
          color: renderer.prop("background", Color.popups.background)
          radius: Style.cornerRadius
          border.width: Style.normalBorderWidth
          border.color: nativeTextArea.activeFocus ? renderer.prop("accent", Color.accent) : renderer.prop("foreground", renderer.foreground)
        }
        onTextChanged: {
          if (text.length > maximumLengthValue) {
            remove(maximumLengthValue, text.length)
            return
          }
          if (!supportsTextEditedSignal && activeFocus) sendInputEvent()
        }
        onActiveFocusChanged: {
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", { value: text })
          if (!activeFocus && renderer.subscribed("change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: text })
        }
        onSelectedTextChanged: {
          if (renderer.subscribed("selection")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection", { start: selectionStart, end: selectionEnd, text: selectedText })
        }
        Connections {
          target: nativeTextArea
          ignoreUnknownSignals: true
          function onTextEdited() { nativeTextArea.sendInputEvent() }
        }
      }
    }
