import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: blurRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  FastBlur {
    anchors.fill: parent
    source: sourceHost
    radius: Number(renderer.prop("radius", 32))
    transparentBorder: renderer.prop("transparent_border", false) === true
    cached: renderer.prop("cached", false) === true
  }
}
