import QtQuick
import QtQuick.Particles

// QtQuick.Particles/LineShape. Emitters and affectors reference it by control id
// and read `nativeExtruder` from it.
Item {
  id: lineShapeRoot
  property var renderer: null
  readonly property var nativeExtruder: lineExtruder

  LineShape {
    id: lineExtruder
    mirrored: lineShapeRoot.renderer ? lineShapeRoot.renderer.prop("mirrored", false) === true : false
  }
}
