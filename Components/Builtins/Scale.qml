import QtQuick

Item {
  id: scaleRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", scaleContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", scaleContent.implicitHeight))
  clip: renderer.prop("clip", false) === true

  transform: Scale {
    origin.x: Number(renderer.prop("origin_x", 0))
    origin.y: Number(renderer.prop("origin_y", 0))
    origin.z: Number(renderer.prop("origin_z", 0))
    xScale: Number(renderer.prop("x_scale", 1))
    yScale: Number(renderer.prop("y_scale", 1))
    zScale: Number(renderer.prop("z_scale", 1))
  }

  Item {
    id: scaleContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
