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

  HueSaturation {
    anchors.fill: parent
    source: sourceHost
    hue: Number(renderer.prop("hue", 0))
    saturation: Number(renderer.prop("saturation", 0))
    lightness: Number(renderer.prop("lightness", 0))
    cached: renderer.prop("cached", false) === true
  }
}
