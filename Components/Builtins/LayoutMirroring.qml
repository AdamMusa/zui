import QtQuick

Item {
  id: mirroringRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", mirroringContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", mirroringContent.implicitHeight))

  Item {
    id: mirroringContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    LayoutMirroring.enabled: renderer.prop("enabled", true) !== false
    LayoutMirroring.childrenInherit: renderer.prop("children_inherit", true) !== false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
