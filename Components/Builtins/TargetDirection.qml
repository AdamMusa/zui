import QtQuick
import QtQuick.Particles

// QtQuick.Particles/TargetDirection. Emitters, affectors and image particles
// reference a direction by control id and read `nativeDirection` from it.
Item {
  id: targetDirectionRoot
  property var renderer: null
  readonly property var nativeDirection: targetDirection
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target_item", "")) : null

  TargetDirection {
    id: targetDirection
    targetItem: targetDirectionRoot.targetItem
    targetX: targetDirectionRoot.renderer ? Number(targetDirectionRoot.renderer.prop("target_x", 0)) : 0
    targetY: targetDirectionRoot.renderer ? Number(targetDirectionRoot.renderer.prop("target_y", 0)) : 0
    targetVariation: targetDirectionRoot.renderer ? Number(targetDirectionRoot.renderer.prop("target_variation", 0)) : 0
    magnitude: targetDirectionRoot.renderer ? Number(targetDirectionRoot.renderer.prop("magnitude", 0)) : 0
    magnitudeVariation: targetDirectionRoot.renderer ? Number(targetDirectionRoot.renderer.prop("magnitude_variation", 0)) : 0
    proportionalMagnitude: targetDirectionRoot.renderer
      ? targetDirectionRoot.renderer.prop("proportional_magnitude", false) === true
      : false
  }
}
