import QtQuick

Item {
  id: translateRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", translateContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", translateContent.implicitHeight))
  clip: renderer.prop("clip", false) === true

  transform: Translate {
    x: Number(renderer.prop("offset_x", 0))
    y: Number(renderer.prop("offset_y", 0))
  }

  Item {
    id: translateContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
