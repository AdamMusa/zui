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

  GaussianBlur {
    anchors.fill: parent
    source: sourceHost
    samples: Math.max(0, Math.round(Number(renderer.prop("samples", 17))))
    radius: Number(renderer.prop("radius", Math.floor(samples / 2)))
    deviation: Number(renderer.prop("deviation", (radius + 1.0) / 3.3333))
    transparentBorder: renderer.prop("transparent_border", false) === true
    cached: renderer.prop("cached", false) === true
  }
}
