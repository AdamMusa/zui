import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Shows one of its children at a time according to how far the camera
// is, so a distant model can be drawn by a cheaper mesh. distances lists
// the switch-over distance before each child after the first.
LodManager {
    id: lodManager

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    camera: renderer.sceneObject(renderer.prop("camera", ""))
    distances: renderer.prop("distances", [])

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: lodManager
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: lodManager.renderer
        target: lodManager
        name: "fade_distance"
        property: "fadeDistance"
        value: Number(lodManager.renderer.prop("fade_distance"))
    }
}
