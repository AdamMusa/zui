import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.TextField {
  required property var renderer
      text: String(renderer.prop("text", "")); placeholderText: String(renderer.prop("placeholder", ""))
      password: renderer.prop("password", false) === true
      implicitWidth: Number(renderer.prop("width", 240)); foreground: renderer.prop("foreground", renderer.foreground)
      accent: renderer.prop("accent", Color.accent); selectionTint: renderer.prop("selection_tint", Style.selectionFillFor(foreground, accent))
      horizontalPadding: Number(renderer.prop("horizontal_padding", Style.spacing.controlPaddingX))
      verticalPadding: Number(renderer.prop("vertical_padding", Style.spacing.inputPaddingY)); hasCursor: renderer.prop("cursor", false) === true
      onTextEdited: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: text })
      onEditingFinished: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: text })
      onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "submit", { value: text })
      onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", { value: text })
    }
