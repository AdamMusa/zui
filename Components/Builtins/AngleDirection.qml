import QtQuick
import QtQuick.Particles

// QtQuick.Particles/AngleDirection. Emitters, affectors and image particles
// reference a direction by control id and read `nativeDirection` from it.
Item {
  id: angleDirectionRoot
  property var renderer: null
  readonly property var nativeDirection: angleDirection

  AngleDirection {
    id: angleDirection
    angle: angleDirectionRoot.renderer ? Number(angleDirectionRoot.renderer.prop("angle", 0)) : 0
    magnitude: angleDirectionRoot.renderer ? Number(angleDirectionRoot.renderer.prop("magnitude", 0)) : 0
    angleVariation: angleDirectionRoot.renderer ? Number(angleDirectionRoot.renderer.prop("angle_variation", 0)) : 0
    magnitudeVariation: angleDirectionRoot.renderer ? Number(angleDirectionRoot.renderer.prop("magnitude_variation", 0)) : 0
  }
}
