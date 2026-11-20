import QtQuick
import QtQuick.VirtualKeyboard

// A HandwritingInputPanel reads `inputPanel.keyboard` and its style as soon as
// it is created. Created without an input panel -- the declaration the
// showcase makes, "declare cleanly and stay inert" -- Qt's own QML threw seven
// "Cannot read property ... of null" errors every time the node was built. The
// panel is therefore only instantiated once the virtual keyboard it belongs to
// has been found among the rendered items; until then the node is inert.
Item {
  id: root
  required property var renderer

  property var panelTarget: null

  function resolvePanel() {
    var target = String(renderer.prop("input_panel", ""))
    panelTarget = target === "" ? null : renderer.findRenderedItem(target)
  }

  implicitWidth: Number(renderer.prop("width", parent ? parent.width : 390))
  implicitHeight: Number(renderer.prop("height", parent ? parent.height : 844))
  width: implicitWidth
  height: implicitHeight
  z: Number(renderer.prop("z", 999))

  Component.onCompleted: resolvePanel()
  Connections {
    target: root.renderer
    function onNodeChanged() { root.resolvePanel() }
  }
  // The keyboard may be built after this node, so keep looking until found.
  Timer {
    interval: 50
    repeat: true
    running: String(root.renderer.prop("input_panel", "")) !== "" && root.panelTarget === null
    onTriggered: root.resolvePanel()
  }

  Loader {
    id: panelLoader
    anchors.fill: parent
    active: root.panelTarget !== null
    sourceComponent: HandwritingInputPanel {
      inputPanel: root.panelTarget
      available: root.renderer.prop("available", false) === true
      active: root.renderer.prop("active", false) === true
      visible: root.renderer.prop("visible", true) !== false && enabled && available && active

      onAvailableChanged: if (root.renderer && root.renderer.bridge) root.renderer.bridge.sendEvent(
        root.renderer.surfaceName, root.renderer.controlId, "available_change", { value: available })
      onActiveChanged: if (root.renderer && root.renderer.bridge) root.renderer.bridge.sendEvent(
        root.renderer.surfaceName, root.renderer.controlId, "active_change", { value: active })
      onEnabledChanged: if (root.renderer && root.renderer.bridge) root.renderer.bridge.sendEvent(
        root.renderer.surfaceName, root.renderer.controlId, "enabled_change", { value: enabled })
    }
  }
}
