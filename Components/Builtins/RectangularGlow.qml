import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: glowRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  RectangularGlow {
    anchors.fill: parent
    glowRadius: Number(renderer.prop("glow_radius", 20))
    spread: Number(renderer.prop("spread", 0))
    color: renderer.prop("color", "white")
    cornerRadius: Number(renderer.prop("corner_radius", glowRadius))
    cached: renderer.prop("cached", false) === true
  }

  Item {
    anchors.fill: parent
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
