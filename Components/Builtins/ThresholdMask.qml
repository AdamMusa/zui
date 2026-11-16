import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: maskRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  function maskItem() {
    var target = String(renderer.prop("mask_source", ""))
    if (target === "") return null
    var resolved = renderer.findRenderedItem(target)
    if (!resolved) renderer.componentError("mask_source_missing", "No rendered item with id " + target, { mask_source: target })
    return resolved
  }

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  ThresholdMask {
    anchors.fill: parent
    source: sourceHost
    maskSource: maskRoot.maskItem()
    threshold: Number(renderer.prop("threshold", 0))
    spread: Number(renderer.prop("spread", 0))
    cached: renderer.prop("cached", false) === true
  }
}
