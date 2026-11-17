import QtQuick
import QtQuick.Effects

Item {
  id: blurRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240)); implicitHeight: Number(renderer.prop("height", 160))

  // MultiEffect.source takes any Item, not only this component's own children.
  // A `source_item` names one by id so an effect can be applied to content that
  // already lives elsewhere in the tree.
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
    anchors.fill: parent; source: blurRoot.effectSource(); blurEnabled: true
    blur: Number(renderer.prop("amount", 0.5)); blurMax: Number(renderer.prop("maximum", 32)); blurMultiplier: Number(renderer.prop("multiplier", 1))
    autoPaddingEnabled: renderer.prop("auto_padding", true) !== false
  }
}
