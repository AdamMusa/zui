import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: overlayRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  ColorOverlay {
    anchors.fill: parent
    source: sourceHost
    color: renderer.prop("color", "transparent")
    cached: renderer.prop("cached", false) === true
  }
}
