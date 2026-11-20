import QtQuick

Item {
  id: rotationRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", rotationContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", rotationContent.implicitHeight))
  clip: renderer.prop("clip", false) === true

  transform: Rotation {
    origin.x: Number(renderer.prop("origin_x", 0))
    origin.y: Number(renderer.prop("origin_y", 0))
    origin.z: Number(renderer.prop("origin_z", 0))
    angle: Number(renderer.prop("angle", 0))
    axis.x: Number(renderer.prop("axis_x", 0))
    axis.y: Number(renderer.prop("axis_y", 0))
    axis.z: Number(renderer.prop("axis_z", 1))
  }

  Item {
    id: rotationContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
