import QtQuick
import QtQuick.VirtualKeyboard

InputPanel {
  id: root
  required property var renderer

  width: Number(renderer.prop("width", parent ? parent.width : 390))
  y: Number(renderer.prop("y", parent ? parent.height - implicitHeight : 0))
  z: Number(renderer.prop("z", 1000))
  visible: renderer.prop("visible", true) !== false && active
  externalLanguageSwitchEnabled: renderer.prop("external_language_switch", false) === true

  onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "active_change", { value: active, height: height })
  onExternalLanguageSwitch: function(localeList, currentIndex) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "language_switch",
      { locales: localeList.map(String), current_index: currentIndex })
  }
  function synchronize() {
    if (renderer.node && renderer.node.props && renderer.node.props.active !== undefined)
      active = renderer.node.props.active === true
  }
  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { root.synchronize() } }
}
