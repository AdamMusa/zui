import QtQuick
import QtQuick.Particles

// QtQuick.Particles/PointDirection. Emitters, affectors and image particles
// reference a direction by control id and read `nativeDirection` from it.
Item {
  id: pointDirectionRoot
  property var renderer: null
  readonly property var nativeDirection: pointDirection

  PointDirection {
    id: pointDirection
    x: pointDirectionRoot.renderer ? Number(pointDirectionRoot.renderer.prop("x", 0)) : 0
    y: pointDirectionRoot.renderer ? Number(pointDirectionRoot.renderer.prop("y", 0)) : 0
    xVariation: pointDirectionRoot.renderer ? Number(pointDirectionRoot.renderer.prop("x_variation", 0)) : 0
    yVariation: pointDirectionRoot.renderer ? Number(pointDirectionRoot.renderer.prop("y_variation", 0)) : 0
  }
}
