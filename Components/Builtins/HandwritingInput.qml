import QtQuick
import QtQuick.VirtualKeyboard

HandwritingInputPanel {
  id: root
  required property var renderer

  inputPanel: renderer.findRenderedItem(renderer.prop("input_panel", ""))
  available: renderer.prop("available", false) === true
  active: renderer.prop("active", false) === true
  width: Number(renderer.prop("width", parent ? parent.width : 390))
  height: Number(renderer.prop("height", parent ? parent.height : 844))
  z: Number(renderer.prop("z", 999))
  visible: renderer.prop("visible", true) !== false && enabled && available && active

  onAvailableChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "available_change", { value: available })
  onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "active_change", { value: active })
  onEnabledChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "enabled_change", { value: enabled })
}
