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

  DirectionalBlur {
    anchors.fill: parent
    source: sourceHost
    angle: Number(renderer.prop("angle", 0))
    length: Number(renderer.prop("length", 32))
    samples: Math.max(0, Math.round(Number(renderer.prop("samples", 24))))
    transparentBorder: renderer.prop("transparent_border", false) === true
    cached: renderer.prop("cached", false) === true
  }
}
