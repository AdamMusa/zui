import QtQuick

Item {
  id: columnRoot

  required property var renderer
  // Every TableModelColumn role maps to a key in the row object. Only the keys
  // Ruby declared are forwarded, so Qt keeps its own defaults for the rest.
  readonly property var roleKeys: ["display", "decoration", "edit", "tool_tip", "status_tip",
    "whats_this", "font", "text_alignment", "background", "foreground", "check_state",
    "accessible_text", "accessible_description", "size_hint"]

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function spec() {
    var result = {}
    for (var index = 0; index < roleKeys.length; index++) {
      var key = roleKeys[index]
      var value = String(renderer.prop(key, ""))
      if (value !== "") result[key] = value
    }
    return result
  }

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", spec())
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { columnRoot.publish() } }
}
