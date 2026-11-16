import QtQuick

Item {
  id: inputMethodRoot
  required property var renderer
  property int handledCommandRevision: -1
  implicitWidth: 0
  implicitHeight: 0

  function directionName(value) {
    return value === Qt.RightToLeft ? "right_to_left" : "left_to_right"
  }

  function rectangle(value) {
    return { x: value.x, y: value.y, width: value.width, height: value.height }
  }

  function publish() {
    if (!renderer.subscribed("change")) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      visible: Qt.inputMethod.visible,
      animating: Qt.inputMethod.animating,
      locale: String(Qt.inputMethod.locale.name),
      input_direction: inputMethodRoot.directionName(Qt.inputMethod.inputDirection),
      keyboard_rectangle: inputMethodRoot.rectangle(Qt.inputMethod.keyboardRectangle),
      cursor_rectangle: inputMethodRoot.rectangle(Qt.inputMethod.cursorRectangle),
      anchor_rectangle: inputMethodRoot.rectangle(Qt.inputMethod.anchorRectangle),
      input_item_clip_rectangle: inputMethodRoot.rectangle(Qt.inputMethod.inputItemClipRectangle)
    })
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", ""))
    if (command === "show") Qt.inputMethod.show()
    else if (command === "hide") Qt.inputMethod.hide()
    else if (command === "reset") Qt.inputMethod.reset()
    else if (command === "commit") Qt.inputMethod.commit()
    else if (command === "update") Qt.inputMethod.update(Qt.ImQueryAll)
  }

  Component.onCompleted: { processCommand(); publish() }
  Connections { target: renderer; function onNodeChanged() { inputMethodRoot.processCommand() } }
  Connections {
    target: Qt.inputMethod
    enabled: renderer.subscribed("change")
    function onVisibleChanged() { inputMethodRoot.publish() }
    function onAnimatingChanged() { inputMethodRoot.publish() }
    function onKeyboardRectangleChanged() { inputMethodRoot.publish() }
    function onCursorRectangleChanged() { inputMethodRoot.publish() }
    function onLocaleChanged() { inputMethodRoot.publish() }
    function onInputDirectionChanged() { inputMethodRoot.publish() }
  }
}
