import QtQuick
import QtQuick.Effects

Item {
  id: colorizeRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240)); implicitHeight: Number(renderer.prop("height", 160))

  function effectSource() {
    var target = String(renderer.prop("source_item", ""))
    if (target === "") return sourceTexture
    var resolved = renderer.findRenderedItem(target)
    if (resolved) return resolved
    renderer.componentError("source_item_missing", "No rendered item with id " + target, { source_item: target })
    return sourceTexture
  }

  Item { id: sourceHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  ShaderEffectSource { id: sourceTexture; anchors.fill: parent; sourceItem: sourceHost; hideSource: true; visible: false }
  MultiEffect {
    anchors.fill: parent; source: colorizeRoot.effectSource()
    colorization: Number(renderer.prop("amount", 1)); colorizationColor: renderer.prop("color", "white")
    brightness: Number(renderer.prop("brightness", 0)); contrast: Number(renderer.prop("contrast", 0)); saturation: Number(renderer.prop("saturation", 0))
  }
}
