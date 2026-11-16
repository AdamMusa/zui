import QtQuick
import QtQuick.Particles

// QtQuick.Particles/MaskShape. Emitters and affectors reference it by control id
// and read `nativeExtruder` from it.
Item {
  id: maskShapeRoot
  property var renderer: null
  readonly property var nativeExtruder: maskExtruder

  MaskShape {
    id: maskExtruder
    source: maskShapeRoot.renderer
      ? maskShapeRoot.renderer.assetUrl(maskShapeRoot.renderer.prop("source", ""))
      : ""
  }
}
