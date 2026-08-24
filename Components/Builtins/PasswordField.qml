import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      id: passwordRoot
      property bool revealState: renderer.prop("revealed", false) === true
      readonly property bool canReveal: renderer.prop("revealable", true) !== false
      implicitWidth: Number(renderer.prop("width", 260))
      implicitHeight: passwordInput.implicitHeight
      ZuiControls.TextField {
        id: passwordInput
        width: passwordRoot.width - (passwordRoot.canReveal ? passwordRoot.height : 0)
        anchors.left: parent.left
        text: String(renderer.prop("text", ""))
        placeholderText: String(renderer.prop("placeholder", ""))
        password: !passwordRoot.revealState
        foreground: renderer.prop("foreground", renderer.foreground)
        accent: renderer.prop("accent", Color.accent)
        selectionTint: renderer.prop("selection_tint", Style.selectionFillFor(foreground, accent))
        horizontalPadding: Number(renderer.prop("horizontal_padding", Style.spacing.controlPaddingX))
        verticalPadding: Number(renderer.prop("vertical_padding", Style.spacing.inputPaddingY))
        onTextEdited: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: text })
        onEditingFinished: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: text })
        onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "submit", { value: text })
        onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", { value: text })
      }
      Rectangle {
        visible: passwordRoot.canReveal
        anchors.right: parent.right
        width: parent.height
        height: parent.height
        color: "transparent"
        Text {
          anchors.centerIn: parent
          text: renderer.iconGlyph(passwordRoot.revealState ? "eye_slash" : "eye")
          textFormat: Text.PlainText
          color: renderer.foreground
          font.family: renderer.iconFontFamily
          font.pixelSize: Style.font.icon
        }
        TapHandler {
          onTapped: {
            passwordRoot.revealState = !passwordRoot.revealState
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reveal", { value: passwordRoot.revealState })
          }
        }
      }
      Connections {
        target: root
        function onNodeChanged() { passwordRoot.revealState = renderer.prop("revealed", passwordRoot.revealState) === true }
      }
    }
