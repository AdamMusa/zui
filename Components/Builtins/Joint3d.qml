import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// One bone of a skeleton. Its index is the row the mesh's joint weights
// refer to, so it has to match the index the asset was authored with.
Joint {
    id: joint3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    skeletonRoot: renderer.sceneObject(renderer.prop("skeleton_root", ""))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: joint3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: joint3d.renderer
        target: joint3d
        name: "index"
        property: "index"
        value: Number(joint3d.renderer.prop("index"))
    }
}
