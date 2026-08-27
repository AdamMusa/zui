import QtQuick
import QtQuick.VirtualKeyboard

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  visible: false
  VirtualKeyboard.extraDictionaries: renderer.prop("extra_dictionaries", []) || []

  function payload() {
    return {
      locale: String(InputContext.locale), uppercase: InputContext.uppercase,
      shift: InputContext.shift, caps_lock: InputContext.capsLock,
      cursor_position: InputContext.cursorPosition, anchor_position: InputContext.anchorPosition,
      surrounding_text: String(InputContext.surroundingText), selected_text: String(InputContext.selectedText),
      preedit_text: String(InputContext.preeditText), animating: InputContext.animating
    }
  }

  function publish(eventName) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, payload())
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "commit"))
    if (command === "commit") InputContext.commit(String(renderer.prop("text", "")))
    else if (command === "key") InputContext.sendKeyClick(Number(renderer.prop("key", 0)),
      String(renderer.prop("text", "")), Number(renderer.prop("modifiers", 0)))
  }

  Component.onCompleted: { publish("change"); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.processCommand() } }
  Connections {
    target: InputContext
    enabled: root.renderer.prop("watch", true) !== false
    function onLocaleChanged() { root.publish("locale_change") }
    function onSurroundingTextChanged() { root.publish("change") }
    function onSelectedTextChanged() { root.publish("change") }
    function onCursorPositionChanged() { root.publish("change") }
  }
}
