import QtQuick
import QtQuick.Effects

Item {
  id: shadowRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))
  RectangularShadow {
    anchors.fill: parent
    blur: Number(renderer.prop("blur", 20))
    spread: Number(renderer.prop("spread", 0))
    radius: Number(renderer.prop("radius", 0))
    offset: Qt.vector2d(Number(renderer.prop("offset_x", 0)), Number(renderer.prop("offset_y", 4)))
    color: renderer.prop("color", "#80000000")
    cached: renderer.prop("cached", true) !== false
    antialiasing: renderer.prop("antialiasing", true) !== false
  }
  Item {
    anchors.fill: parent
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
}
