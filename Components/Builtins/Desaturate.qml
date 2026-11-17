import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: adjustRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  Desaturate {
    anchors.fill: parent
    source: sourceHost
    desaturation: Number(renderer.prop("desaturation", 1))
    cached: renderer.prop("cached", false) === true
  }
}
