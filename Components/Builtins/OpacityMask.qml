import QtQuick
import QtQuick.Effects

Item {
  id: maskRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))
  function effectSource() {
    var target = String(renderer.prop("source_item", ""))
    if (target === "") return sourceTexture
    var resolved = renderer.findRenderedItem(target)
    if (resolved) return resolved
    renderer.componentError("source_item_missing", "No rendered item with id " + target, { source_item: target })
    return sourceTexture
  }

  function maskItem() {
    var target = String(renderer.prop("mask_source", ""))
    if (target === "") return null
    var resolved = renderer.findRenderedItem(target)
    if (!resolved) renderer.componentError("mask_source_missing", "No rendered item with id " + target, { mask_source: target })
    return resolved
  }

  Item { id: sourceHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  ShaderEffectSource { id: sourceTexture; anchors.fill: parent; sourceItem: sourceHost; hideSource: true; visible: false }
  MultiEffect {
    anchors.fill: parent
    source: maskRoot.effectSource()
    maskEnabled: true
    maskSource: maskRoot.maskItem()
    maskThresholdMin: Number(renderer.prop("threshold_min", 0))
    maskSpreadAtMin: Number(renderer.prop("spread_min", 0))
    maskThresholdMax: Number(renderer.prop("threshold_max", 1))
    maskSpreadAtMax: Number(renderer.prop("spread_max", 0))
    maskInverted: renderer.prop("inverted", false) === true
  }
}
