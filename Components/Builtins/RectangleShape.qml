import QtQuick
import QtQuick.Particles

// QtQuick.Particles/RectangleShape. Emitters and affectors reference it by
// control id and read `nativeExtruder` from it.
Item {
  id: rectangleShapeRoot
  property var renderer: null
  readonly property var nativeExtruder: rectangleExtruder

  RectangleShape {
    id: rectangleExtruder
    fill: rectangleShapeRoot.renderer ? rectangleShapeRoot.renderer.prop("fill", true) !== false : true
  }
}
