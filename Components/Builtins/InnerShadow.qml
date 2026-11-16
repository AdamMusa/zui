import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: shadowRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  InnerShadow {
    anchors.fill: parent
    source: sourceHost
    radius: Number(renderer.prop("radius", 8))
    samples: Math.max(0, Math.round(Number(renderer.prop("samples", 17))))
    spread: Number(renderer.prop("spread", 0))
    color: renderer.prop("color", "black")
    horizontalOffset: Number(renderer.prop("horizontal_offset", 0))
    verticalOffset: Number(renderer.prop("vertical_offset", 0))
    fast: renderer.prop("fast", false) === true
    cached: renderer.prop("cached", false) === true
  }
}
