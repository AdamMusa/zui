import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: blurRoot
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

  MaskedBlur {
    anchors.fill: parent
    source: sourceHost
    maskSource: blurRoot.maskItem()
    radius: Number(renderer.prop("radius", 8))
    samples: Math.max(0, Math.round(Number(renderer.prop("samples", 17))))
    cached: renderer.prop("cached", false) === true
  }
}
