import QtQuick
import QtQuick.Controls as QQC
import QtQuick.VirtualKeyboard

QQC.TextField {
  id: root
  required property var renderer
  VirtualKeyboard.extraDictionaries: renderer.prop("extra_dictionaries", []) || []
  EnterKeyAction.actionId: {
    var name = String(renderer.prop("enter_key", "enter"))
    var values = { none: EnterKeyAction.None, enter: EnterKeyAction.None, return_key: EnterKeyAction.None,
      go: EnterKeyAction.Go, search: EnterKeyAction.Search, send: EnterKeyAction.Send,
      next: EnterKeyAction.Next, done: EnterKeyAction.Done }
    return values[name] === undefined ? EnterKeyAction.None : values[name]
  }
  EnterKeyAction.label: String(renderer.prop("enter_key_label", ""))
  EnterKeyAction.enabled: renderer.prop("enter_key_enabled", true) !== false
  text: String(renderer.prop("text", ""))
  placeholderText: String(renderer.prop("placeholder", ""))
  inputMethodHints: Number(renderer.prop("input_method_hints", 0))
  implicitWidth: Number(renderer.prop("width", 280))
  implicitHeight: Number(renderer.prop("height", 52))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  onTextEdited: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: text })
  onTextChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: text })
  onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", { value: text })
  Keys.onPressed: function(event) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "key",
      { key: event.key, text: event.text, modifiers: Number(event.modifiers) })
  }
}
