import QtQuick
import QtQuick.Particles

// QtQuick.Particles/EllipseShape. Emitters and affectors reference it by control
// id and read `nativeExtruder` from it.
Item {
  id: ellipseShapeRoot
  property var renderer: null
  readonly property var nativeExtruder: ellipseExtruder

  EllipseShape {
    id: ellipseExtruder
    fill: ellipseShapeRoot.renderer ? ellipseShapeRoot.renderer.prop("fill", false) === true : false
  }
}
