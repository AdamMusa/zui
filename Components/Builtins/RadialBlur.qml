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

  RadialBlur {
    anchors.fill: parent
    source: sourceHost
    angle: Number(renderer.prop("angle", 30))
    samples: Math.max(0, Math.round(Number(renderer.prop("samples", 24))))
    horizontalOffset: Number(renderer.prop("horizontal_offset", 0))
    verticalOffset: Number(renderer.prop("vertical_offset", 0))
    transparentBorder: renderer.prop("transparent_border", false) === true
    cached: renderer.prop("cached", false) === true
  }
}
