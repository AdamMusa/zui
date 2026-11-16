import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: displaceRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  function displacementItem() {
    var target = String(renderer.prop("displacement_source", ""))
    if (target === "") return null
    var resolved = renderer.findRenderedItem(target)
    if (!resolved) renderer.componentError("displacement_source_missing", "No rendered item with id " + target, { displacement_source: target })
    return resolved
  }

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  Displace {
    anchors.fill: parent
    source: sourceHost
    displacementSource: displaceRoot.displacementItem()
    displacement: Number(renderer.prop("displacement", 0))
    cached: renderer.prop("cached", false) === true
  }
}
